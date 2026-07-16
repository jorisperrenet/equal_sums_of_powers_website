-- Every (5, 4, 1) and (5, 3, 2) identity is also a (5, 5; 0)
-- identity after moving the right-hand terms to the left. Keep these four
-- target rows in sync with the newer, authoritative equality records.

INSERT INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT
  'derived-55n-from-seed-541-euler',
  '5-5-n',
  contributor_id,
  json_array(
    -CAST(json_extract(right_terms, '$[0]') AS INTEGER),
    CAST(json_extract(left_terms, '$[0]') AS INTEGER),
    CAST(json_extract(left_terms, '$[1]') AS INTEGER),
    CAST(json_extract(left_terms, '$[2]') AS INTEGER),
    CAST(json_extract(left_terms, '$[3]') AS INTEGER)
  ),
  '[0]',
  tool_text,
  discovered_at
FROM submissions
WHERE id = 'seed-541-euler';

WITH replacements(target_id, source_id, left_terms) AS (VALUES
  (
    'mse-5139124-7d1c9a8f0803868c0556',
    'braun-paper-541-2004',
    '[-85359,85282,28969,3183,55]'
  ),
  (
    'braun-paper-55n-1996',
    'scher-seidl-5-3-2-1996',
    '[-14132,14068,6237,5027,-220]'
  ),
  (
    'braun-paper-55n-2026',
    'mrexcel-5-3-2-2026-07-10',
    '[-1956878,1956213,-1340632,1331622,719115]'
  )
)
UPDATE submissions AS target
SET contributor_id = source.contributor_id,
    left_terms = replacements.left_terms,
    right_terms = '[0]',
    tool_text = source.tool_text,
    discovered_at = source.discovered_at
FROM replacements
JOIN submissions AS source ON source.id = replacements.source_id
WHERE target.id = replacements.target_id;

-- A target row should cite the same sources as the equality it was derived
-- from. In particular, replace the stale Math Stack Exchange attribution on
-- the J. Frye row with the source attached to the (5, 4, 1) record.
DELETE FROM submission_resources
WHERE submission_id IN (
  'derived-55n-from-seed-541-euler',
  'mse-5139124-7d1c9a8f0803868c0556',
  'braun-paper-55n-1996',
  'braun-paper-55n-2026'
);

WITH mappings(target_id, source_id) AS (VALUES
  ('derived-55n-from-seed-541-euler', 'seed-541-euler'),
  ('mse-5139124-7d1c9a8f0803868c0556', 'braun-paper-541-2004'),
  ('braun-paper-55n-1996', 'scher-seidl-5-3-2-1996'),
  ('braun-paper-55n-2026', 'mrexcel-5-3-2-2026-07-10')
)
INSERT INTO submission_resources (submission_id, resource_id, role)
SELECT mappings.target_id, source.resource_id, source.role
FROM mappings
JOIN submission_resources AS source ON source.submission_id = mappings.source_id;
