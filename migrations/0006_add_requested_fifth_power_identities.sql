-- Identities supplied in July 2026. Some are alternate category views of the
-- same mathematical identity, so they deliberately occur in both categories.

INSERT OR IGNORE INTO contributors (name) VALUES ('Mrexcel');
INSERT OR IGNORE INTO contributors (name) VALUES ('Eugene Go');

-- 3214^5 + 10896^5 + 19615^5 + 31810^5 = 32386^5 - 1.
INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT
  'simon-goater-5-4-1-pm1-32386',
  '5-4-1-pm1',
  id,
  '[31810,19615,10896,3214]',
  '[32386,-1]',
  NULL,
  '2026-07-16T00:00:00Z'
FROM contributors
WHERE name = 'Simon Goater';

-- 719115^5 + 1331622^5 + 1956213^5 = 1340632^5 + 1956878^5.
INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT
  'mrexcel-5-3-2-2026-07-10',
  '5-3-2',
  id,
  '[1956213,1331622,719115]',
  '[1956878,1340632]',
  NULL,
  '2026-07-10T00:00:00Z'
FROM contributors
WHERE name = 'Mrexcel';

-- Rearranged from 1 + 73487^5 + 53823^5 = 76111^5 + 12340^5 + 33220^5.
INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT
  'eugene-go-5-3-2-pm1-2026-07-16',
  '5-3-2-pm1',
  id,
  '[76111,33220,12340]',
  '[73487,53823,1]',
  NULL,
  '2026-07-16T00:00:00Z'
FROM contributors
WHERE name = 'Eugene Go';

-- Simon Goater's (5, 5; N) identities.
INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT 'simon-goater-5-5-n-1-30965', '5-5-n', id,
  '[32919,-30965,-27764,24271,-18410]', '[1]', NULL, '2026-07-16T00:00:00Z'
FROM contributors WHERE name = 'Simon Goater';

UPDATE search_claims
SET comment = NULL
WHERE id = 'mse-5143215-dm-radius-7000';

DROP TRIGGER submissions_target_n_bounds;

CREATE TRIGGER submissions_target_n_bounds
BEFORE INSERT ON submissions
WHEN EXISTS (
  SELECT 1
  FROM categories
  WHERE id = NEW.category_id AND format = 'target'
) AND (
  CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER) < 0 OR
  CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER) > 2500
)
BEGIN
  SELECT RAISE(ABORT, 'N must be between 0 and 2500');
END;

INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT 'simon-goater-5-5-n-1-32386', '5-5-n', id,
  '[32386,-31810,-19615,-10896,-3214]', '[1]', NULL, '2026-07-16T00:00:00Z'
FROM contributors WHERE name = 'Simon Goater';

INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT 'simon-goater-5-5-n-6', '5-5-n', id,
  '[17,-16,-15,13,7]', '[6]', NULL, '2026-07-16T00:00:00Z'
FROM contributors WHERE name = 'Simon Goater';

INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT 'simon-goater-5-5-n-8', '5-5-n', id,
  '[-78,71,65,-38,18]', '[8]', NULL, '2026-07-16T00:00:00Z'
FROM contributors WHERE name = 'Simon Goater';

INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT 'simon-goater-5-5-n-10', '5-5-n', id,
  '[-17,16,13,-1,-1]', '[10]', NULL, '2026-07-16T00:00:00Z'
FROM contributors WHERE name = 'Simon Goater';

INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT 'simon-goater-5-5-n-2', '5-5-n', id,
  '[7896,-7845,-6772,6487,4466]', '[2]', NULL, '2026-07-16T00:00:00Z'
FROM contributors WHERE name = 'Simon Goater';

INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT 'simon-goater-5-5-n-4', '5-5-n', id,
  '[-574,540,441,-264,251]', '[4]', NULL, '2026-07-16T00:00:00Z'
FROM contributors WHERE name = 'Simon Goater';

-- Explicit results from the public Stack Exchange chat transcript.
INSERT OR IGNORE INTO contributors (name) VALUES ('mezzoctane');

INSERT OR IGNORE INTO resources (title, url)
VALUES (
  'Stack Exchange chat: fifth-power target results',
  'https://chat.stackexchange.com/rooms/164134/discussion-on-answer-by-danielv-can-2025-and-2026-be-written-as-sums-of-five'
);

WITH incoming(id, contributor, left_terms, target, discovered_at) AS (VALUES
  ('chat-164134-simon-2077', 'Simon Goater', '[-2244,2021,1874,591,-135]', 2077, '2026-06-16T16:09:13Z'),
  ('chat-164134-mezzoctane-2026', 'mezzoctane', '[88,-83,-67,26,-8]', 2026, '2026-06-16T16:09:13Z'),
  ('chat-164134-mezzoctane-2027', 'mezzoctane', '[47,-43,-41,32,-8]', 2027, '2026-06-16T16:09:13Z'),
  ('chat-164134-simon-2041', 'Simon Goater', '[-2711,2683,1480,789,250]', 2041, '2026-06-16T16:09:13Z'),
  ('chat-164134-guruprasad-2052', 'Guruprasad', '[10922,-9695,-9212,-5094,371]', 2052, '2026-06-16T16:09:13Z'),
  ('chat-164134-guruprasad-2062', 'Guruprasad', '[-3737,3612,3188,-2969,1728]', 2062, '2026-06-16T16:09:13Z'),
  ('chat-164134-guruprasad-2084', 'Guruprasad', '[7714,-7574,-5964,4997,4591]', 2084, '2026-06-16T16:09:13Z'),
  ('chat-164134-guruprasad-2091', 'Guruprasad', '[-9281,8324,7568,5043,3817]', 2091, '2026-06-16T16:09:13Z'),
  ('chat-164134-guruprasad-2093', 'Guruprasad', '[-6651,6374,-4364,5273,-609]', 2093, '2026-06-16T16:09:13Z'),
  ('chat-164134-aleksandr-2010', 'Aleksandr', '[4219,-4209,-1736,-122,-42]', 2010, '2026-06-16T16:09:13Z'),
  ('chat-164134-aleksandr-2025', 'Aleksandr', '[-10620,9794,8523,331,-93]', 2025, '2026-06-16T16:09:13Z'),
  ('chat-164134-aleksandr-2037', 'Aleksandr', '[2398,-2360,-1435,-282,26]', 2037, '2026-06-16T16:09:13Z'),
  ('chat-164134-aleksandr-2038', 'Aleksandr', '[1208,-1102,-989,-250,51]', 2038, '2026-06-16T16:09:13Z'),
  ('chat-164134-simon-125', 'Simon Goater', '[-3786,3507,3166,-2185,-1837]', 125, '2026-06-19T22:39:50Z'),
  ('chat-164134-simon-260', 'Simon Goater', '[-6142,6122,3203,-2927,1804]', 260, '2026-06-19T22:39:50Z'),
  ('chat-164134-simon-2100', 'Simon Goater', '[14681,-14316,-10805,9234,-3504]', 2100, '2026-07-05T12:29:48Z'),
  ('chat-164134-simon-2090', 'Simon Goater', '[56146,-55945,-54565,54487,-23023]', 2090, '2026-07-07T06:31:40Z'),
  ('chat-164134-simon-2092', 'Simon Goater', '[32157,-31457,-20366,-9962,7150]', 2092, '2026-07-14T16:32:08Z'),
  ('chat-164134-eugene-2013', 'Eugene Go', '[-62280,60456,42591,-23377,-20657]', 2013, '2026-07-16T11:49:07Z'),
  ('chat-164134-eugene-2073', 'Eugene Go', '[-270071,261925,182779,6439,-4759]', 2073, '2026-07-16T11:49:07Z')
)
INSERT OR IGNORE INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT incoming.id, '5-5-n', contributors.id, incoming.left_terms,
       json_array(incoming.target), NULL, incoming.discovered_at
FROM incoming
JOIN contributors ON contributors.name = incoming.contributor;

INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT submissions.id, resources.id, 'source'
FROM submissions
JOIN resources ON resources.url = 'https://chat.stackexchange.com/rooms/164134/discussion-on-answer-by-danielv-can-2025-and-2026-be-written-as-sums-of-five'
WHERE submissions.id LIKE 'chat-164134-%'
   OR submissions.id = 'mse-5139124-f6eda5018504a7efc93b';
