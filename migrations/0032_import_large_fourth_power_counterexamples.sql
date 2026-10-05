-- The four counterexamples to Euler's conjecture, A^4 = B^4 + C^4 + D^4, that
-- Seiji Tomita lists (http://www.maroon.dti.ne.jp/fermat/dioph46e.html, read
-- 2026-10-05) but migration 0019 left out because their terms exceeded the
-- site's old limit of 10^15. Terms of any size are stored since migration 0030.
-- With these, every solution on that page is on the site. Dates and credit are
-- Tomita's; the 28-digit identity is also in the Euler database
-- (http://euler.free.fr/database.txt) with the same date. Each identity was
-- verified with exact BigInt arithmetic before this file was written. Purely
-- additive, and a row is skipped if its identity is somehow already present.
INSERT OR IGNORE INTO contributors (name) VALUES ('Seiji Tomita'), ('M. A. Fajjal');

INSERT OR IGNORE INTO resources (title, url) VALUES
  ('Current status of A^4 = B^4 + C^4 + D^4', 'http://www.maroon.dti.ne.jp/fermat/dioph46e.html'),
  ('Euler equal sums of like powers database', 'http://euler.free.fr/database.txt');

WITH incoming(id, contributor, left_terms, right_terms, discovered_at) AS (VALUES
  ('tomita-413-20249506709579721', 'Seiji Tomita', '["20249506709579721"]', '["18565945114216720","14890026433468471",3579087147375440]', '2008-08-13T00:00:00Z'),
  ('tomita-413-62940516903410601', 'Seiji Tomita', '["62940516903410601"]', '["56827813308111785","47886740272114976",8813425670440240]', '2008-08-13T00:00:00Z'),
  ('tomita-413-1677479490238223823661446513', 'Seiji Tomita', '["1677479490238223823661446513"]', '["1507524066882038472584786800","1288056982586427591062203384","169218021322170204480680305"]', '2006-03-13T00:00:00Z'),
  ('tomita-413-9161781830035436847832452398267266038227002962257243662070370888722169', 'M. A. Fajjal', '["9161781830035436847832452398267266038227002962257243662070370888722169"]', '["9033964577482532388059482429398457291004947925005743028147465732645880","4417264698994538496943597489754952845854672497179047898864124209346920","1439965710648954492268506771833175267850201426615300442218292336336633"]', '2009-05-31T00:00:00Z')
)
INSERT INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT incoming.id, '4-1-3', contributor.id,
       incoming.left_terms, incoming.right_terms, NULL, incoming.discovered_at
FROM incoming
JOIN contributors AS contributor ON contributor.name = incoming.contributor
WHERE NOT EXISTS (
  SELECT 1 FROM submissions existing
  WHERE existing.category_id = '4-1-3'
    AND existing.left_terms = incoming.left_terms
    AND existing.right_terms = incoming.right_terms
);

INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT submission.id, resource.id, 'source'
FROM submissions AS submission
JOIN resources AS resource ON resource.url = 'http://www.maroon.dti.ne.jp/fermat/dioph46e.html'
WHERE submission.id IN (
  'tomita-413-20249506709579721',
  'tomita-413-62940516903410601',
  'tomita-413-1677479490238223823661446513',
  'tomita-413-9161781830035436847832452398267266038227002962257243662070370888722169'
);

INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT submission.id, resource.id, 'source'
FROM submissions AS submission
JOIN resources AS resource ON resource.url = 'http://euler.free.fr/database.txt'
WHERE submission.id = 'tomita-413-1677479490238223823661446513';
