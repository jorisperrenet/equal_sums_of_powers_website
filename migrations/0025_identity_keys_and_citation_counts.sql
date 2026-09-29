-- Two additions so that neither submitting nor the references page reads every
-- submission: cheap duplicate checks and stored citation counts. Every change
-- is additive: one new column, one view, one index, one table and triggers. The only existing rows written are submissions.identity_key (new,
-- previously absent) on every submission.

-- 1. A canonical identity key per submission, so a new submission is checked
--    for duplicates with one index lookup per line instead of reading and
--    normalizing every row of its category. Legacy imports store the terms in
--    non-canonical order (see migration 0024), which the existing
--    UNIQUE(category_id, left_terms, right_terms) index cannot see through.
--
--    The key mirrors identityKey() in src/lib/identity.ts exactly:
--      equality   sorted left '=' sorted right, sides swapped for a:a categories
--                 so the lexicographically larger side comes first
--      near_miss  sorted left '=' sorted right bases ',' residual
--      target     signed terms by |x| desc then x desc, negated when N = 0 and the
--                 leading term is negative, '=' N
--    The index is deliberately not UNIQUE: a production row that duplicates a
--    legacy import must not make this migration fail.
ALTER TABLE submissions ADD COLUMN identity_key TEXT;

CREATE VIEW submission_identity_keys AS
SELECT s.id, CASE c.format
  WHEN 'target' THEN
    (SELECT group_concat(
        CAST(l.value AS INTEGER) * CASE
          WHEN CAST(json_extract(s.right_terms, '$[0]') AS INTEGER) = 0
           AND (SELECT CAST(f.value AS INTEGER) FROM json_each(s.left_terms) f
                ORDER BY ABS(CAST(f.value AS INTEGER)) DESC, CAST(f.value AS INTEGER) DESC
                LIMIT 1) < 0
          THEN -1 ELSE 1 END,
        ',' ORDER BY ABS(CAST(l.value AS INTEGER)) DESC, CAST(l.value AS INTEGER) DESC)
     FROM json_each(s.left_terms) l)
    || '=' ||
    (SELECT group_concat(CAST(r.value AS INTEGER), ',' ORDER BY r.key)
     FROM json_each(s.right_terms) r)
  WHEN 'near_miss' THEN
    (SELECT group_concat(CAST(l.value AS INTEGER), ',' ORDER BY CAST(l.value AS INTEGER) DESC)
     FROM json_each(s.left_terms) l)
    || '=' ||
    COALESCE(
      (SELECT group_concat(CAST(r.value AS INTEGER), ',' ORDER BY CAST(r.value AS INTEGER) DESC)
       FROM json_each(s.right_terms) r
       WHERE r.key < json_array_length(s.right_terms) - 1) || ',',
      '')
    || CAST(json_extract(s.right_terms, '$[#-1]') AS INTEGER)
  ELSE
    CASE WHEN c.left_count = c.right_count
      AND (SELECT group_concat(printf('%020d', CAST(l.value AS INTEGER)), '' ORDER BY CAST(l.value AS INTEGER) DESC)
           FROM json_each(s.left_terms) l)
        < (SELECT group_concat(printf('%020d', CAST(r.value AS INTEGER)), '' ORDER BY CAST(r.value AS INTEGER) DESC)
           FROM json_each(s.right_terms) r)
    THEN
      (SELECT group_concat(CAST(r.value AS INTEGER), ',' ORDER BY CAST(r.value AS INTEGER) DESC)
       FROM json_each(s.right_terms) r)
      || '=' ||
      (SELECT group_concat(CAST(l.value AS INTEGER), ',' ORDER BY CAST(l.value AS INTEGER) DESC)
       FROM json_each(s.left_terms) l)
    ELSE
      (SELECT group_concat(CAST(l.value AS INTEGER), ',' ORDER BY CAST(l.value AS INTEGER) DESC)
       FROM json_each(s.left_terms) l)
      || '=' ||
      (SELECT group_concat(CAST(r.value AS INTEGER), ',' ORDER BY CAST(r.value AS INTEGER) DESC)
       FROM json_each(s.right_terms) r)
    END
  END AS identity_key
FROM submissions s
JOIN categories c ON c.id = s.category_id;

UPDATE submissions
SET identity_key = (SELECT k.identity_key FROM submission_identity_keys k WHERE k.id = submissions.id);

CREATE INDEX submissions_by_category_identity ON submissions(category_id, identity_key);

-- The key is always derived in SQL, so the site, later migrations and manual
-- edits can never store one that disagrees with the terms.
CREATE TRIGGER submissions_identity_key_after_insert
AFTER INSERT ON submissions
BEGIN
  UPDATE submissions
  SET identity_key = (SELECT k.identity_key FROM submission_identity_keys k WHERE k.id = NEW.id)
  WHERE id = NEW.id;
END;

CREATE TRIGGER submissions_identity_key_after_update
AFTER UPDATE OF category_id, left_terms, right_terms ON submissions
BEGIN
  UPDATE submissions
  SET identity_key = (SELECT k.identity_key FROM submission_identity_keys k WHERE k.id = NEW.id)
  WHERE id = NEW.id;
END;

-- 2. How many distinct submissions cite each resource, for the references
--    page. Counting live walks every submission link (tens of thousands once a
--    large category is imported), however few resources there are. Search-claim
--    and category links stay counted live: those tables hold a few dozen rows.
--    A submission citing one resource as both tool and source counts once,
--    matching the page's COUNT(DISTINCT submission_id), hence the pair checks.
CREATE TABLE resource_submission_counts (
  resource_id INTEGER PRIMARY KEY REFERENCES resources(id) ON DELETE CASCADE,
  submission_count INTEGER NOT NULL
);

INSERT INTO resource_submission_counts (resource_id, submission_count)
SELECT r.id,
  (SELECT COUNT(DISTINCT submission_id) FROM submission_resources sr WHERE sr.resource_id = r.id)
FROM resources r;

CREATE TRIGGER resource_submission_counts_after_resource_insert AFTER INSERT ON resources
BEGIN INSERT INTO resource_submission_counts (resource_id, submission_count) VALUES (NEW.id, 0); END;
CREATE TRIGGER resource_submission_counts_after_resource_delete AFTER DELETE ON resources
BEGIN DELETE FROM resource_submission_counts WHERE resource_id = OLD.id; END;

CREATE TRIGGER resource_submission_counts_after_link_insert AFTER INSERT ON submission_resources
WHEN (SELECT COUNT(*) FROM submission_resources
      WHERE submission_id = NEW.submission_id AND resource_id = NEW.resource_id) = 1
BEGIN
  UPDATE resource_submission_counts SET submission_count = submission_count + 1
  WHERE resource_id = NEW.resource_id;
END;
CREATE TRIGGER resource_submission_counts_after_link_delete AFTER DELETE ON submission_resources
WHEN NOT EXISTS (SELECT 1 FROM submission_resources
                 WHERE submission_id = OLD.submission_id AND resource_id = OLD.resource_id)
BEGIN
  UPDATE resource_submission_counts SET submission_count = submission_count - 1
  WHERE resource_id = OLD.resource_id;
END;
-- A role change keeps the pair and so the count; only a moved link counts.
CREATE TRIGGER resource_submission_counts_after_link_update
AFTER UPDATE OF submission_id, resource_id ON submission_resources
WHEN OLD.submission_id IS NOT NEW.submission_id OR OLD.resource_id IS NOT NEW.resource_id
BEGIN
  UPDATE resource_submission_counts SET submission_count = submission_count - 1
  WHERE resource_id = OLD.resource_id
    AND NOT EXISTS (SELECT 1 FROM submission_resources
                    WHERE submission_id = OLD.submission_id AND resource_id = OLD.resource_id);
  UPDATE resource_submission_counts SET submission_count = submission_count + 1
  WHERE resource_id = NEW.resource_id
    AND (SELECT COUNT(*) FROM submission_resources
         WHERE submission_id = NEW.submission_id AND resource_id = NEW.resource_id) = 1;
END;
