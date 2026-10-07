-- A third elliptic-curve family for (4, 1, 4), and older sources for three
-- of its solutions. Additive: new contributors and resources, four new rows,
-- and three guarded updates of existing rows.
--
-- 1. Solutions with two equal terms, 2a⁴ + c⁴ + d⁴ = e⁴. Matej Veselovac
--    showed on 2026-10-07 (https://mathoverflow.net/q/515812) that each lies on
--    an elliptic curve with infinitely many such solutions, using an identity
--    of Bremner, Choudhry and Ulas (arXiv:1402.4583). family_k (migration
--    0030) now also holds 'a=b' for these, after any k values
--    (src/lib/elliptic-family.ts), so the same partial indexes, family table
--    and ?k= filter serve them. Eugene Go's exhaustive table (e ≤ 10^7,
--    completed 2026-08-02) has exactly one such solution; the other three are
--    Veselovac's, the 50-digit one in the question and the 9- and 25-digit
--    ones in his answer (https://mathoverflow.net/a/515813). Each identity was
--    verified with exact BigInt arithmetic, is primitive, and has no k.
INSERT OR IGNORE INTO contributors (name) VALUES
  ('Eugene Go'),
  ('Matej Veselovac'),
  ('Allan MacLeod'),
  ('Kermit Rose and Simcha Brudno'),
  ('Jaroslaw Wroblewski');

INSERT OR IGNORE INTO resources (title, url) VALUES
  ('MO: A third family of elliptic curves, 2a^4+c^4+d^4=e^4', 'https://mathoverflow.net/q/515812'),
  ('MO: Smaller solutions of 2a^4+c^4+d^4=e^4', 'https://mathoverflow.net/a/515813'),
  ('MacLeod: Computational experiments on a^4+b^4+c^4+d^4=(a+b+c+d)^4 (arXiv:1704.03200)', 'https://arxiv.org/abs/1704.03200'),
  ('Rose and Brudno: More about four biquadrates equal one biquadrate (Math. Comp. 1973)', 'https://doi.org/10.1090/S0025-5718-1973-0329184-2'),
  ('Wroblewski: Equal sums and differences of 4th powers (414.txt)', 'https://www.math.uni.wroc.pl/~jwr/eslp/414.txt');

INSERT OR IGNORE INTO category_resources (category_id, resource_id)
SELECT '4-1-4', id FROM resources WHERE url = 'https://mathoverflow.net/q/515812';

WITH incoming(id, contributor, left_terms, right_terms, discovered_at, identity_key) AS (VALUES
  ('family-414-193120427', 'Matej Veselovac', '[193120427]', '[152390000,152390000,132216661,51012080]', '2026-10-07T00:00:00Z', '193120427=152390000,152390000,132216661,51012080'),
  ('family-414-325193', 'Eugene Go', '[325193]', '[249568,244580,244580,110135]', '2026-08-02T00:00:00Z', '325193=249568,244580,244580,110135'),
  ('family-414-1339532416841228401950369', 'Matej Veselovac', '["1339532416841228401950369"]', '["1238463349050993305729744","810330621656459740582780","810330621656459740582780","263547411669024704967135"]', '2026-10-07T00:00:00Z', '1339532416841228401950369=1238463349050993305729744,810330621656459740582780,810330621656459740582780,263547411669024704967135'),
  ('family-414-22927647769158648735501102355876548323298415196953', 'Matej Veselovac', '["22927647769158648735501102355876548323298415196953"]', '["17630451516830948295545486687367765389873646909460","17630451516830948295545486687367765389873646909460","16917724959611226646590322140308024444914707328672","5868947341118257621079172383221425502854039783065"]', '2026-10-07T00:00:00Z', '22927647769158648735501102355876548323298415196953=17630451516830948295545486687367765389873646909460,17630451516830948295545486687367765389873646909460,16917724959611226646590322140308024444914707328672,5868947341118257621079172383221425502854039783065')
)
INSERT INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at, family_k)
SELECT incoming.id, '4-1-4', contributor.id,
       incoming.left_terms, incoming.right_terms, NULL, incoming.discovered_at, 'a=b'
FROM incoming
JOIN contributors AS contributor ON contributor.name = incoming.contributor
WHERE NOT EXISTS (
  SELECT 1 FROM submissions existing
  WHERE existing.category_id = '4-1-4' AND existing.identity_key = incoming.identity_key
);

-- 2. Older sources, reported by Veselovac on 2026-10-05 and checked against
--    them: MacLeod's arXiv paper (submitted 2017-04-11) has the 25-digit
--    solution, Wroblewski's table has e = 65659 (and e = 14489), and Rose and
--    Brudno published e = 14489 in Math. Comp. 27 (July 1973), Table 1. Each
--    update only applies while the row still has the credit migration 0031
--    gave it.
UPDATE submissions
SET contributor_id = (SELECT id FROM contributors WHERE name = 'Allan MacLeod'),
    discovered_at = '2017-04-11T00:00:00Z'
WHERE id = 'family-414-8883141110487747038812249'
  AND contributor_id = (SELECT id FROM contributors WHERE name = 'Matej Veselovac')
  AND discovered_at = '2026-09-24T00:00:00Z';

UPDATE submissions
SET contributor_id = (SELECT id FROM contributors WHERE name = 'Kermit Rose and Simcha Brudno'),
    discovered_at = '1973-07-01T00:00:00Z'
WHERE id = 'family-414-14489'
  AND contributor_id = (SELECT id FROM contributors WHERE name = 'Eugene Go')
  AND discovered_at = '2026-08-02T00:00:00Z';

UPDATE submissions
SET contributor_id = (SELECT id FROM contributors WHERE name = 'Jaroslaw Wroblewski'),
    discovered_at = '2006-01-01T00:00:00Z'
WHERE id = 'family-414-65659'
  AND contributor_id = (SELECT id FROM contributors WHERE name = 'Eugene Go')
  AND discovered_at = '2026-08-02T00:00:00Z';

WITH links(submission_id, url) AS (VALUES
  ('family-414-325193', 'https://mathoverflow.net/q/515812'),
  ('family-414-325193', 'https://math.stackexchange.com/a/5145556'),
  ('family-414-22927647769158648735501102355876548323298415196953', 'https://mathoverflow.net/q/515812'),
  ('family-414-193120427', 'https://mathoverflow.net/a/515813'),
  ('family-414-1339532416841228401950369', 'https://mathoverflow.net/a/515813'),
  ('family-414-8883141110487747038812249', 'https://arxiv.org/abs/1704.03200'),
  ('family-414-14489', 'https://doi.org/10.1090/S0025-5718-1973-0329184-2'),
  ('family-414-14489', 'https://www.math.uni.wroc.pl/~jwr/eslp/414.txt'),
  ('family-414-65659', 'https://www.math.uni.wroc.pl/~jwr/eslp/414.txt')
)
INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT submission.id, resource.id, 'source'
FROM links
JOIN submissions AS submission ON submission.id = links.submission_id
JOIN resources AS resource ON resource.url = links.url;
