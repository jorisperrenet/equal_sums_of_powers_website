-- Correct the attribution of Jeffrey Braun's 2026 fifth-power identity and
-- record the earlier Scher-Seidl identity cited in Braun's paper.

INSERT OR IGNORE INTO contributors (name) VALUES ('Jeffrey Braun');
INSERT OR IGNORE INTO contributors (name) VALUES ('B. Scher and E. Seidl');

INSERT OR IGNORE INTO resources (title, url)
VALUES (
  'The fourth known primitive solution to a^5+b^5+c^5+d^5=e^5',
  'https://ar5iv.labs.arxiv.org/html/2603.05549'
);

-- 719115^5 + 1331622^5 + 1956213^5 = 1340632^5 + 1956878^5.
UPDATE submissions
SET contributor_id = (SELECT id FROM contributors WHERE name = 'Jeffrey Braun'),
    discovered_at = '2026-03-05T00:00:00Z'
WHERE category_id = '5-3-2'
  AND left_terms = '[1956213,1331622,719115]'
  AND right_terms = '[1956878,1340632]';

-- Rearranged from (-220)^5 + 5027^5 + 6237^5 + 14068^5 = 14132^5.
INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT
  'scher-seidl-5-3-2-1996',
  '5-3-2',
  id,
  '[14068,6237,5027]',
  '[14132,220]',
  NULL,
  '1996-01-01T00:00:00Z'
FROM contributors
WHERE name = 'B. Scher and E. Seidl';

UPDATE submissions
SET contributor_id = (SELECT id FROM contributors WHERE name = 'B. Scher and E. Seidl'),
    discovered_at = '1996-01-01T00:00:00Z'
WHERE category_id = '5-3-2'
  AND left_terms = '[14068,6237,5027]'
  AND right_terms = '[14132,220]';

INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT submissions.id, resources.id, 'source'
FROM submissions
JOIN resources ON resources.url = 'https://ar5iv.labs.arxiv.org/html/2603.05549'
WHERE submissions.category_id = '5-3-2'
  AND (
    (submissions.left_terms = '[1956213,1331622,719115]'
     AND submissions.right_terms = '[1956878,1340632]')
    OR
    (submissions.left_terms = '[14068,6237,5027]'
     AND submissions.right_terms = '[14132,220]')
  );

DELETE FROM contributors
WHERE name = 'Mrexcel'
  AND NOT EXISTS (
    SELECT 1 FROM submissions WHERE contributor_id = contributors.id
  )
  AND NOT EXISTS (
    SELECT 1 FROM search_claims WHERE contributor_id = contributors.id
  );
