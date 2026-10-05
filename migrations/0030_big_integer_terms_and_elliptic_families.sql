-- Terms of any size, and a marker for the elliptic-curve families in (4, 1, 4).
--
-- Additive: one new column, two partial indexes, and three triggers plus one
-- view replaced by versions that also handle big terms. No existing row is
-- written: every stored term is below 2^53, where the new definitions give
-- exactly the values the old ones stored (npm run check:database verifies
-- max_term and identity_key against the terms).
--
-- 1. Big terms. A term above 2^53 − 1 is stored as a JSON string of its digits
--    (src/lib/terms.ts), since D1 reads big JSON numbers as lossy floats. The
--    old SQL used CAST(value AS INTEGER), which saturates at 2^63 − 1 and so
--    would give every big row the same sort key and broken identity keys. The
--    replacements compare terms as digit strings: longer is larger, and equal
--    lengths compare digit by digit.
--
--    max_term stays an INTEGER whenever the largest term fits a JavaScript
--    number, as before. Otherwise it holds the TEXT 'LLL:digits' with the digit
--    count zero-padded to three places. SQLite orders every INTEGER before
--    every TEXT and TEXT by bytes, so the existing index and the leaderboard's
--    ORDER BY max_term still sort by size, and the colon keeps INTEGER column
--    affinity from turning the text into a lossy float.
DROP TRIGGER submissions_normalize_after_insert;
DROP TRIGGER submissions_max_term_after_update;

CREATE TRIGGER submissions_normalize_after_insert
AFTER INSERT ON submissions
WHEN NEW.max_term IS NULL
  OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.discovered_at) IS NOT NEW.discovered_at
BEGIN
  UPDATE submissions
  SET max_term = COALESCE(max_term,
        (SELECT CASE
           WHEN length(d) < 16 OR (length(d) = 16 AND d <= '9007199254740991')
           THEN CAST(d AS INTEGER)
           ELSE printf('%03d:%s', length(d), d)
         END
         FROM (SELECT ltrim(CAST(value AS TEXT), '-') AS d FROM json_each(left_terms)
               UNION ALL
               SELECT ltrim(CAST(value AS TEXT), '-') FROM json_each(right_terms))
         ORDER BY length(d) DESC, d DESC LIMIT 1)),
      discovered_at = COALESCE(strftime('%Y-%m-%dT%H:%M:%SZ', discovered_at), discovered_at)
  WHERE id = NEW.id;
END;

CREATE TRIGGER submissions_max_term_after_update
AFTER UPDATE OF left_terms, right_terms ON submissions
BEGIN
  UPDATE submissions
  SET max_term =
        (SELECT CASE
           WHEN length(d) < 16 OR (length(d) = 16 AND d <= '9007199254740991')
           THEN CAST(d AS INTEGER)
           ELSE printf('%03d:%s', length(d), d)
         END
         FROM (SELECT ltrim(CAST(value AS TEXT), '-') AS d FROM json_each(left_terms)
               UNION ALL
               SELECT ltrim(CAST(value AS TEXT), '-') FROM json_each(right_terms))
         ORDER BY length(d) DESC, d DESC LIMIT 1)
  WHERE id = NEW.id;
END;

--    The identity key (see migration 0025 and identityKey() in
--    src/lib/identity.ts) is rebuilt from the terms' digit strings. Sorting
--    uses the digit count, then the digits; signed target terms sort by
--    absolute value, then positive before negative. The comparison that puts
--    the larger side of an a:a category first concatenates
--    zero-padded-length-plus-digits per term, which orders sides exactly as
--    the old fixed-width printf('%020d') did for terms below 10^20.
DROP VIEW submission_identity_keys;

CREATE VIEW submission_identity_keys AS
SELECT s.id, CASE c.format
  WHEN 'target' THEN
    (SELECT group_concat(
        CASE
          WHEN (SELECT f.t FROM (SELECT CAST(value AS TEXT) AS t FROM json_each(s.left_terms)) f
                ORDER BY length(ltrim(f.t, '-')) DESC, ltrim(f.t, '-') DESC, f.t LIKE '-%' ASC
                LIMIT 1) LIKE '-%'
           AND CAST(json_extract(s.right_terms, '$[0]') AS INTEGER) = 0
          THEN CASE WHEN l.t LIKE '-%' THEN substr(l.t, 2) WHEN l.t = '0' THEN l.t ELSE '-' || l.t END
          ELSE l.t
        END,
        ',' ORDER BY length(ltrim(l.t, '-')) DESC, ltrim(l.t, '-') DESC, l.t LIKE '-%' ASC)
     FROM (SELECT CAST(value AS TEXT) AS t FROM json_each(s.left_terms)) l)
    || '=' ||
    (SELECT group_concat(CAST(r.value AS INTEGER), ',' ORDER BY r.key)
     FROM json_each(s.right_terms) r)
  WHEN 'near_miss' THEN
    (SELECT group_concat(l.t, ',' ORDER BY length(l.t) DESC, l.t DESC)
     FROM (SELECT CAST(value AS TEXT) AS t FROM json_each(s.left_terms)) l)
    || '=' ||
    COALESCE(
      (SELECT group_concat(r.t, ',' ORDER BY length(r.t) DESC, r.t DESC)
       FROM (SELECT CAST(value AS TEXT) AS t FROM json_each(s.right_terms)
             WHERE key < json_array_length(s.right_terms) - 1) r) || ',',
      '')
    || CAST(json_extract(s.right_terms, '$[#-1]') AS INTEGER)
  ELSE
    CASE WHEN c.left_count = c.right_count
      AND (SELECT group_concat(printf('%03d', length(l.t)) || l.t, '' ORDER BY length(l.t) DESC, l.t DESC)
           FROM (SELECT CAST(value AS TEXT) AS t FROM json_each(s.left_terms)) l)
        < (SELECT group_concat(printf('%03d', length(r.t)) || r.t, '' ORDER BY length(r.t) DESC, r.t DESC)
           FROM (SELECT CAST(value AS TEXT) AS t FROM json_each(s.right_terms)) r)
    THEN
      (SELECT group_concat(r.t, ',' ORDER BY length(r.t) DESC, r.t DESC)
       FROM (SELECT CAST(value AS TEXT) AS t FROM json_each(s.right_terms)) r)
      || '=' ||
      (SELECT group_concat(l.t, ',' ORDER BY length(l.t) DESC, l.t DESC)
       FROM (SELECT CAST(value AS TEXT) AS t FROM json_each(s.left_terms)) l)
    ELSE
      (SELECT group_concat(l.t, ',' ORDER BY length(l.t) DESC, l.t DESC)
       FROM (SELECT CAST(value AS TEXT) AS t FROM json_each(s.left_terms)) l)
      || '=' ||
      (SELECT group_concat(r.t, ',' ORDER BY length(r.t) DESC, r.t DESC)
       FROM (SELECT CAST(value AS TEXT) AS t FROM json_each(s.right_terms)) r)
    END
  END AS identity_key
FROM submissions s
JOIN categories c ON c.id = s.category_id;

-- 2. The elliptic-curve families of (4, 1, 4): solutions with
--    e = a + k³(b + c + d) for rational k (src/lib/elliptic-family.ts). k is
--    stored as 'n' or 'n/m', comma-separated in the unlikely case of several;
--    NULL means none. SQL cannot test for rational cubes, so the site and import
--    migrations fill it in and npm run check:database recomputes it. The partial
--    indexes hold only family rows, so listing a few hundred of them never
--    reads the rest of a category of tens of thousands.
ALTER TABLE submissions ADD COLUMN family_k TEXT;

CREATE INDEX submissions_family_by_max_term
  ON submissions(category_id, max_term, discovered_at, id) WHERE family_k IS NOT NULL;
CREATE INDEX submissions_family_by_date
  ON submissions(category_id, discovered_at, id) WHERE family_k IS NOT NULL;

-- k is displayed, so changing it must bump the page-cache version (migration 0027).
DROP TRIGGER site_version_after_submissions_update;
CREATE TRIGGER site_version_after_submissions_update AFTER UPDATE OF category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at, family_k ON submissions
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
