-- Complete the two signs of the (5, 3, 2; +/-1) list supplied in July 2026.
-- The first two +1 identities are already present as seed-533-01/02.

INSERT OR IGNORE INTO contributors (name) VALUES ('wxffles');

WITH incoming(id, contributor, left_terms, right_terms, discovered_at) AS (VALUES
  ('duncan-moore-5-3-2-pm1-328', 'Duncan Moore', '[5,388,705]', '[328,709,1]', '2026-06-08T00:00:00Z'),
  ('duncan-moore-5-3-2-pm1-588', 'Duncan Moore', '[59,511,791]', '[588,772,1]', '2026-06-08T00:00:00Z'),
  ('duncan-moore-5-3-2-pm1-561', 'Duncan Moore', '[401,616,1146]', '[561,1151,1]', '2026-06-08T00:00:00Z'),
  ('duncan-moore-5-3-2-pm1-1073', 'Duncan Moore', '[379,686,2306]', '[1073,2297,1]', '2026-06-08T00:00:00Z'),
  ('duncan-moore-5-3-2-pm1-4167', 'Duncan Moore', '[1039,2601,4811]', '[4167,4283,1]', '2026-06-08T00:00:00Z'),
  ('duncan-moore-5-3-2-pm1-4823', 'Duncan Moore', '[1089,3501,6611]', '[4823,6377,1]', '2026-06-08T00:00:00Z'),
  ('wxffles-5-3-2-pm1-541', 'wxffles', '[151,317,623]', '[541,551,-1]', '2026-06-08T00:00:00Z'),
  ('wxffles-5-3-2-pm1-571', 'wxffles', '[63,475,707]', '[571,675,-1]', '2026-06-08T00:00:00Z'),
  ('simon-goater-5-3-2-pm1-1654', 'Simon Goater', '[699,763,1974]', '[1654,1783,-1]', '2026-07-03T00:00:00Z'),
  ('simon-goater-5-3-2-pm1-611', 'Simon Goater', '[781,882,2648]', '[611,2651,-1]', '2026-07-03T00:00:00Z'),
  ('simon-goater-5-3-2-pm1-2316', 'Simon Goater', '[1286,2029,3299]', '[2316,3249,-1]', '2026-07-03T00:00:00Z'),
  ('simon-goater-5-3-2-pm1-355', 'Simon Goater', '[1660,3903,4044]', '[355,4573,-1]', '2026-07-03T00:00:00Z'),
  ('simon-goater-5-3-2-pm1-9317', 'Simon Goater', '[2937,5509,11479]', '[9317,10609,-1]', '2026-06-08T00:00:00Z'),
  ('simon-goater-5-3-2-pm1-12776', 'Simon Goater', '[293,12237,15357]', '[12776,15112,-1]', '2026-06-08T00:00:00Z'),
  ('simon-goater-5-3-2-pm1-8183', 'Simon Goater', '[3208,5659,17542]', '[8183,17477,-1]', '2026-06-08T00:00:00Z'),
  ('simon-goater-5-3-2-pm1-8451', 'Simon Goater', '[1333,7104,24912]', '[8451,24899,-1]', '2026-06-08T00:00:00Z')
)
INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT incoming.id, '5-3-2-pm1', contributors.id, incoming.left_terms,
       incoming.right_terms, NULL, incoming.discovered_at
FROM incoming
JOIN contributors ON contributors.name = incoming.contributor;

-- Correct the attribution of the existing signed (5, 5; N=1) views.
UPDATE submissions
SET contributor_id = (SELECT id FROM contributors WHERE name = 'Duncan Moore')
WHERE id IN (
  'mse-5139124-6ff3b517436740ceefe6',
  'mse-5139124-1552ac5f8cbc9b35bd25',
  'mse-5139124-512122972d8fc6c3ead9',
  'mse-5139124-3d2d09ecf67603f5ddb8',
  'mse-5139124-93694ed06880897ee5b0',
  'mse-5139124-8252d9637aa81efb1dca',
  'mse-5139124-25e2041d2934dd46abfe',
  'mse-5139124-52c37dcc5786f1aea6f3'
);

UPDATE submissions
SET contributor_id = (SELECT id FROM contributors WHERE name = 'wxffles')
WHERE id IN (
  'mse-5139124-2d47232220e215a1d519',
  'mse-5139124-99df478601894c09d820'
);

DELETE FROM submission_resources
WHERE resource_id = (
  SELECT id FROM resources
  WHERE url = 'https://github.com/jorisperrenet/equal_sums_of_powers'
)
AND submission_id IN (
  'mse-5139124-6ff3b517436740ceefe6',
  'mse-5139124-1552ac5f8cbc9b35bd25',
  'mse-5139124-512122972d8fc6c3ead9',
  'mse-5139124-3d2d09ecf67603f5ddb8',
  'mse-5139124-93694ed06880897ee5b0',
  'mse-5139124-8252d9637aa81efb1dca',
  'mse-5139124-25e2041d2934dd46abfe',
  'mse-5139124-52c37dcc5786f1aea6f3',
  'mse-5139124-2d47232220e215a1d519',
  'mse-5139124-99df478601894c09d820'
);

-- The source describes separate exhaustive searches for the two residual signs.
INSERT OR IGNORE INTO search_claims
  (id, category_id, contributor_id, lower_radius, upper_radius, search_type, comment, created_at)
SELECT 'duncan-moore-5-3-2-pm1-radius-50000', '5-3-2-pm1', id,
       '0', '50000', 'exhaustive',
       'Complete for the +1 residual with all positive bases below 50000.',
       '2026-07-16T00:00:00Z'
FROM contributors WHERE name = 'Duncan Moore';

INSERT OR IGNORE INTO search_claims
  (id, category_id, contributor_id, lower_radius, upper_radius, search_type, comment, created_at)
SELECT 'simon-goater-5-3-2-pm1-radius-30000', '5-3-2-pm1', id,
       '0', '30000', 'exhaustive',
       'Complete for the -1 residual with all positive bases below 30000; the fixed -1 is excluded from the radius.',
       '2026-07-16T00:00:00Z'
FROM contributors WHERE name = 'Simon Goater';

-- Additional signed fifth-power targets. The two values in the July 15 prose
-- were transposed; exact evaluation gives 59 for the 38800 identity and 55
-- for the 32064 identity.
WITH incoming(id, contributor, left_terms, target, discovered_at) AS (VALUES
  ('simon-goater-5-5-n-59-38800', 'Simon Goater', '[38800,-37045,22356,-29644,-15378]', 59, '2026-07-15T00:00:00Z'),
  ('simon-goater-5-5-n-55-32064', 'Simon Goater', '[32064,-32521,25162,-23778,1078]', 55, '2026-07-15T00:00:00Z'),
  ('simon-goater-5-5-n-228', 'Simon Goater', '[-48992,-39829,-17029,-5303,52101]', 228, '2026-07-16T00:00:00Z'),
  ('eugene-go-5-5-n-169', 'Eugene Go', '[-178679,177584,88771,-6115,5338]', 169, '2026-07-16T00:00:00Z'),
  ('eugene-go-5-5-n-126', 'Eugene Go', '[-165249,165141,51822,29423,22939]', 126, '2026-07-16T00:00:00Z'),
  ('eugene-go-5-5-n-184', 'Eugene Go', '[579598,-556952,-411631,-22496,21095]', 184, '2026-07-16T00:00:00Z')
)
INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT incoming.id, '5-5-n', contributors.id, incoming.left_terms,
       json_array(incoming.target), NULL, incoming.discovered_at
FROM incoming
JOIN contributors ON contributors.name = incoming.contributor;

-- All identities and completeness claims above came through the same public
-- fifth-power-target source already recorded by the project.
INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT submissions.id, resources.id, 'source'
FROM submissions
JOIN resources
  ON resources.url = 'https://mathoverflow.net/questions/512480/on-a3b3c3-n-and-a5b5c5d5e5-n'
WHERE submissions.id LIKE 'duncan-moore-5-3-2-pm1-%'
   OR submissions.id LIKE 'wxffles-5-3-2-pm1-%'
   OR submissions.id LIKE 'simon-goater-5-3-2-pm1-%'
   OR submissions.id IN (
     'simon-goater-5-5-n-59-38800',
     'simon-goater-5-5-n-55-32064',
     'simon-goater-5-5-n-228',
     'eugene-go-5-5-n-169',
     'eugene-go-5-5-n-126',
     'eugene-go-5-5-n-184'
   );

INSERT OR IGNORE INTO search_claim_resources (search_claim_id, resource_id)
SELECT search_claims.id, resources.id
FROM search_claims
JOIN resources
  ON resources.url = 'https://mathoverflow.net/questions/512480/on-a3b3c3-n-and-a5b5c5d5e5-n'
WHERE search_claims.id IN (
  'duncan-moore-5-3-2-pm1-radius-50000',
  'simon-goater-5-3-2-pm1-radius-30000'
);
