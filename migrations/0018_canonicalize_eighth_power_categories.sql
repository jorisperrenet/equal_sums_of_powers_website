-- Equality categories are written as (power, smaller side, larger side).
-- Unlike near-miss categories, swapping equality sides does not change the
-- meaning of the identity.
INSERT INTO categories (id, exponent, left_count, right_count, format, notation)
VALUES
  ('8-3-5', 8, 3, 5, 'equality', NULL),
  ('8-2-6', 8, 2, 6, 'equality', NULL),
  ('8-1-7', 8, 1, 7, 'equality', NULL);

WITH category_renames(old_id, new_id) AS (VALUES
  ('8-5-3', '8-3-5'),
  ('8-6-2', '8-2-6'),
  ('8-7-1', '8-1-7')
)
UPDATE category_resources
SET category_id = category_renames.new_id
FROM category_renames
WHERE category_resources.category_id = category_renames.old_id;

-- Preserve each equality while orienting its terms to the renamed category.
WITH category_renames(old_id, new_id) AS (VALUES
  ('8-5-3', '8-3-5'),
  ('8-6-2', '8-2-6'),
  ('8-7-1', '8-1-7')
)
UPDATE submissions
SET category_id = category_renames.new_id,
    left_terms = submissions.right_terms,
    right_terms = submissions.left_terms
FROM category_renames
WHERE submissions.category_id = category_renames.old_id;

WITH category_renames(old_id, new_id) AS (VALUES
  ('8-5-3', '8-3-5'),
  ('8-6-2', '8-2-6'),
  ('8-7-1', '8-1-7')
)
UPDATE search_claims
SET category_id = category_renames.new_id
FROM category_renames
WHERE search_claims.category_id = category_renames.old_id;

DELETE FROM categories
WHERE id IN ('8-5-3', '8-6-2', '8-7-1');

-- This source entry was previously skipped because its category orientation
-- was the reverse of the category then present in the archive.
INSERT OR IGNORE INTO contributors (name) VALUES ('Scott I. Chase');

INSERT INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT 'euler-835-966', '8-3-5', contributor.id,
       '[966,539,81]', '[954,725,481,310,158]', NULL, '0001-01-01T00:00:00Z'
FROM contributors AS contributor
WHERE contributor.name = 'Scott I. Chase';

INSERT INTO submission_resources (submission_id, resource_id, role)
SELECT 'euler-835-966', resource.id, 'source'
FROM resources AS resource
WHERE resource.url = 'http://euler.free.fr/database.txt';
