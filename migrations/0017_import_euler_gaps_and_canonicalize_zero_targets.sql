-- Import identities present in Jean-Charles Meyrignac's Euler database but
-- absent from the public archive as of 2026-07-27.

INSERT OR IGNORE INTO contributors (name) VALUES
  ('Robert Gerbicz, Leonid Durman, Yuri Radaev, Alexey Zubkov'),
  ('Seiji Tomita'),
  ('Robert Gerbicz'),
  ('Allan MacLeod'),
  ('D.J. Bernstein');

INSERT OR IGNORE INTO resources (title, url) VALUES
  ('Euler equal sums of like powers database', 'http://euler.free.fr/database.txt');

-- The source gives no discovery date for six records. The schema requires a
-- date, so use 0001-01-01 as an explicit unknown-date sentinel for those rows.
WITH incoming(id, category_id, contributor, left_terms, right_terms, discovered_at) AS (VALUES
  ('euler-413-1259768473', '4-1-3', 'Robert Gerbicz, Leonid Durman, Yuri Radaev, Alexey Zubkov', '[1259768473]', '[1166705840,859396455,588903336]', '2008-01-25T00:00:00Z'),
  ('euler-413-873822121',  '4-1-3', 'Robert Gerbicz, Leonid Durman, Yuri Radaev, Alexey Zubkov', '[873822121]',  '[769321280,606710871,558424440]',    '2007-11-02T00:00:00Z'),
  ('euler-413-1787882337', '4-1-3', 'Robert Gerbicz, Leonid Durman, Yuri Radaev, Alexey Zubkov', '[1787882337]', '[1662997663,1237796960,686398000]', '2007-11-02T00:00:00Z'),
  ('euler-413-1871713857', '4-1-3', 'Robert Gerbicz, Leonid Durman, Yuri Radaev, Alexey Zubkov', '[1871713857]', '[1593513080,1553556440,92622401]',  '2007-10-31T00:00:00Z'),
  ('euler-413-3393603777', '4-1-3', 'Seiji Tomita', '[3393603777]', '[3134081336,2448718655,664793200]', '2007-01-28T00:00:00Z'),
  ('euler-413-44310257',   '4-1-3', 'Robert Gerbicz', '[44310257]',   '[41084175,31669120,2164632]',        '2006-11-08T00:00:00Z'),
  ('euler-413-68711097',   '4-1-3', 'Robert Gerbicz', '[68711097]',   '[65932985,42878560,10409096]',       '2006-11-08T00:00:00Z'),
  ('euler-413-117112081',  '4-1-3', 'Robert Gerbicz', '[117112081]',  '[106161120,87865617,34918520]',      '2006-11-02T00:00:00Z'),
  ('euler-413-589845921',  '4-1-3', 'Seiji Tomita', '[589845921]',  '[582665296,260052385,186668000]',    '2006-03-13T00:00:00Z'),
  ('euler-413-1679142729', '4-1-3', 'Seiji Tomita', '[1679142729]', '[1670617271,632671960,50237800]',    '2006-03-13T00:00:00Z'),
  ('euler-413-638523249',  '4-1-3', 'Allan MacLeod', '[638523249]', '[630662624,275156240,219076465]',    '1998-01-01T00:00:00Z'),
  ('euler-413-2813001',    '4-1-3', 'Allan MacLeod', '[2813001]',   '[2767624,1390400,673865]',            '0001-01-01T00:00:00Z'),
  ('euler-413-8707481',    '4-1-3', 'D.J. Bernstein', '[8707481]',  '[8332208,5507880,1705575]',           '0001-01-01T00:00:00Z'),
  ('euler-413-12197457',   '4-1-3', 'D.J. Bernstein', '[12197457]', '[11289040,8282543,5870000]',          '0001-01-01T00:00:00Z'),
  ('euler-413-16003017',   '4-1-3', 'D.J. Bernstein', '[16003017]', '[14173720,12552200,4479031]',         '0001-01-01T00:00:00Z'),
  ('euler-413-16430513',   '4-1-3', 'D.J. Bernstein', '[16430513]', '[16281009,7028600,3642840]',          '0001-01-01T00:00:00Z'),
  ('euler-413-20615673',   '4-1-3', 'Noam Elkies', '[20615673]',   '[18796760,15365639,2682440]',         '1986-01-01T00:00:00Z'),
  ('euler-844-3113',       '8-4-4', 'Nuutti Kuosa', '[3113,2012,1953,861]', '[2823,2767,2557,1128]', '2006-11-09T00:00:00Z')
)
INSERT INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT incoming.id, incoming.category_id, contributor.id,
       incoming.left_terms, incoming.right_terms, NULL, incoming.discovered_at
FROM incoming
JOIN contributors AS contributor ON contributor.name = incoming.contributor;

INSERT INTO submission_resources (submission_id, resource_id, role)
SELECT submission.id, resource.id, 'source'
FROM submissions AS submission
JOIN resources AS resource
  ON resource.url = 'http://euler.free.fr/database.txt'
WHERE submission.id LIKE 'euler-413-%'
   OR submission.id = 'euler-844-3113';

-- This live submission duplicates the historical Lander-Parkin identity once
-- zero-target signs are canonicalized. Remove only Joris Perrenet's 2026 row.
DELETE FROM submissions
WHERE category_id = '5-5-n'
  AND contributor_id = (SELECT id FROM contributors WHERE name = 'Joris Perrenet')
  AND left_terms = '[144,-133,-110,-84,-27]'
  AND right_terms = '[0]'
  AND discovered_at LIKE '2026-07-18%';

-- For N = 0, an identity and its global negation are equivalent. Store the
-- representative whose greatest-absolute-value term is positive.
WITH replacements(id, left_terms) AS (VALUES
  ('derived-55n-from-seed-541-euler', '[144,-133,-110,-84,-27]'),
  ('braun-paper-55n-1996', '[14132,-14068,-6237,-5027,220]'),
  ('braun-paper-55n-2026', '[1956878,-1956213,1340632,-1331622,-719115]'),
  ('mse-5139124-7d1c9a8f0803868c0556', '[85359,-85282,-28969,-3183,-55]')
)
UPDATE submissions
SET left_terms = replacements.left_terms
FROM replacements
WHERE submissions.id = replacements.id
  AND submissions.category_id = '5-5-n'
  AND submissions.right_terms = '[0]';
