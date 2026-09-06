-- Cut the D1 rows read per page load from roughly 25,000 to under 1,000.
-- Every change here is additive: new columns, indexes, one summary table, and
-- triggers that keep the derived values in sync. No existing row is removed.

-- 1. Category submission counts, maintained by triggers instead of counting
--    every submission row on every page load and sitemap fetch.
ALTER TABLE categories ADD COLUMN submission_count INTEGER NOT NULL DEFAULT 0;

UPDATE categories
SET submission_count = (
  SELECT COUNT(*) FROM submissions WHERE submissions.category_id = categories.id
);

CREATE TRIGGER categories_count_after_submission_insert
AFTER INSERT ON submissions
BEGIN
  UPDATE categories SET submission_count = submission_count + 1
  WHERE id = NEW.category_id;
END;

CREATE TRIGGER categories_count_after_submission_delete
AFTER DELETE ON submissions
BEGIN
  UPDATE categories SET submission_count = submission_count - 1
  WHERE id = OLD.category_id;
END;

CREATE TRIGGER categories_count_after_submission_move
AFTER UPDATE OF category_id ON submissions
WHEN OLD.category_id IS NOT NEW.category_id
BEGIN
  UPDATE categories SET submission_count = submission_count - 1
  WHERE id = OLD.category_id;
  UPDATE categories SET submission_count = submission_count + 1
  WHERE id = NEW.category_id;
END;

-- 2. The largest absolute base of each identity, stored once so the default
--    "highest term" ordering is served from an index instead of re-parsing the
--    JSON terms of every row in the category on every request.
ALTER TABLE submissions ADD COLUMN max_term INTEGER;

UPDATE submissions
SET max_term = MAX(
  (SELECT MAX(ABS(CAST(value AS INTEGER))) FROM json_each(left_terms)),
  (SELECT MAX(ABS(CAST(value AS INTEGER))) FROM json_each(right_terms))
);

-- 3. One canonical UTC timestamp format, so plain string order is
--    chronological and ORDER BY no longer needs datetime(), which defeats every
--    index. Imported rows already use 'YYYY-MM-DDTHH:MM:SSZ'; rows written
--    through the CURRENT_TIMESTAMP default use 'YYYY-MM-DD HH:MM:SS' and are
--    rewritten to the same instant in the canonical form.
UPDATE submissions
SET discovered_at = strftime('%Y-%m-%dT%H:%M:%SZ', discovered_at)
WHERE strftime('%Y-%m-%dT%H:%M:%SZ', discovered_at) IS NOT NULL
  AND strftime('%Y-%m-%dT%H:%M:%SZ', discovered_at) != discovered_at;

-- Future inserts (the site and later migrations) may omit max_term and rely on
-- the timestamp default; this trigger fills both in immediately.
CREATE TRIGGER submissions_normalize_after_insert
AFTER INSERT ON submissions
WHEN NEW.max_term IS NULL
  OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.discovered_at) IS NOT NEW.discovered_at
BEGIN
  UPDATE submissions
  SET max_term = COALESCE(max_term, MAX(
        (SELECT MAX(ABS(CAST(value AS INTEGER))) FROM json_each(left_terms)),
        (SELECT MAX(ABS(CAST(value AS INTEGER))) FROM json_each(right_terms)))),
      discovered_at = COALESCE(strftime('%Y-%m-%dT%H:%M:%SZ', discovered_at), discovered_at)
  WHERE id = NEW.id;
END;

CREATE TRIGGER submissions_max_term_after_update
AFTER UPDATE OF left_terms, right_terms ON submissions
BEGIN
  UPDATE submissions
  SET max_term = MAX(
    (SELECT MAX(ABS(CAST(value AS INTEGER))) FROM json_each(left_terms)),
    (SELECT MAX(ABS(CAST(value AS INTEGER))) FROM json_each(right_terms)))
  WHERE id = NEW.id;
END;

-- 4. Indexes matching every leaderboard ordering and the recent-results list
--    exactly, including the id tie-breaker: without it SQLite still sorts the
--    whole category before applying LIMIT.
CREATE INDEX submissions_by_category_max_term
  ON submissions(category_id, max_term, discovered_at, id);

CREATE INDEX submissions_by_category_target
  ON submissions(category_id, CAST(json_extract(right_terms, '$[0]') AS INTEGER), discovered_at, id);

CREATE INDEX submissions_by_category_date_id
  ON submissions(category_id, discovered_at DESC, id DESC);

CREATE INDEX submissions_by_date
  ON submissions(discovered_at DESC, id DESC);

-- 5. Solution counts per integer target, maintained by triggers, so the
--    coverage grid no longer groups every row of the target category.
CREATE TABLE target_coverage (
  category_id TEXT NOT NULL REFERENCES categories(id),
  n INTEGER NOT NULL,
  solution_count INTEGER NOT NULL,
  PRIMARY KEY (category_id, n)
);

INSERT INTO target_coverage (category_id, n, solution_count)
SELECT s.category_id, CAST(json_extract(s.right_terms, '$[0]') AS INTEGER), COUNT(*)
FROM submissions s
JOIN categories c ON c.id = s.category_id
WHERE c.format = 'target'
GROUP BY s.category_id, CAST(json_extract(s.right_terms, '$[0]') AS INTEGER);

CREATE TRIGGER target_coverage_after_insert
AFTER INSERT ON submissions
WHEN (SELECT format FROM categories WHERE id = NEW.category_id) = 'target'
BEGIN
  INSERT INTO target_coverage (category_id, n, solution_count)
  VALUES (NEW.category_id, CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER), 1)
  ON CONFLICT (category_id, n) DO UPDATE SET solution_count = solution_count + 1;
END;

CREATE TRIGGER target_coverage_after_delete
AFTER DELETE ON submissions
WHEN (SELECT format FROM categories WHERE id = OLD.category_id) = 'target'
BEGIN
  UPDATE target_coverage SET solution_count = solution_count - 1
  WHERE category_id = OLD.category_id
    AND n = CAST(json_extract(OLD.right_terms, '$[0]') AS INTEGER);
  DELETE FROM target_coverage WHERE solution_count <= 0;
END;

CREATE TRIGGER target_coverage_after_update
AFTER UPDATE OF category_id, right_terms ON submissions
BEGIN
  UPDATE target_coverage SET solution_count = solution_count - 1
  WHERE category_id = OLD.category_id
    AND n = CAST(json_extract(OLD.right_terms, '$[0]') AS INTEGER)
    AND (SELECT format FROM categories WHERE id = OLD.category_id) = 'target';
  DELETE FROM target_coverage WHERE solution_count <= 0;
  INSERT INTO target_coverage (category_id, n, solution_count)
  SELECT NEW.category_id, CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER), 1
  WHERE (SELECT format FROM categories WHERE id = NEW.category_id) = 'target'
  ON CONFLICT (category_id, n) DO UPDATE SET solution_count = solution_count + 1;
END;
