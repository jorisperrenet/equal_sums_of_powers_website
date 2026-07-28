-- Correct publication-year and unknown-date placeholders using dated historical
-- sources, and import the additional fourth-power identities listed by Seiji
-- Tomita that fit the application's exact-integer representation.

INSERT OR IGNORE INTO contributors (name) VALUES
  ('Roger Frye'),
  ('Juergen Rathmann');

INSERT OR IGNORE INTO resources (title, url) VALUES
  ('Euler conjecture details', 'http://euler.free.fr/details.htm'),
  ('Current status of A^4 = B^4 + C^4 + D^4', 'http://www.maroon.dti.ne.jp/fermat/dioph46e.html'),
  ('Enumerating solutions to p(a) + q(b) = r(c) + s(d)', 'https://cr.yp.to/papers/sortedsums-19990928-retypeset20220327.pdf'),
  ('Diophantine Equation--4th Powers', 'https://mathworld.wolfram.com/DiophantineEquation4thPowers.html');

-- Chase's (8,3,5) identity is dated 2000 on Meyrignac's details page.
UPDATE submissions
SET discovered_at = '2000-01-01T00:00:00Z'
WHERE id = 'euler-835-966';

-- Tomita dates MacLeod's d = 2813001 identity to 1997.
UPDATE submissions
SET discovered_at = '1997-01-01T00:00:00Z'
WHERE id = 'euler-413-2813001';

-- Bernstein's preprint is dated 1999-09-28 and describes these four identities
-- as new. The 2001 date found in some tables is the journal publication year.
UPDATE submissions
SET discovered_at = '1999-09-28T00:00:00Z'
WHERE id IN (
  'euler-413-8707481',
  'euler-413-12197457',
  'euler-413-16003017',
  'euler-413-16430513'
);

-- The smallest counterexample was found by Roger Frye in 1988, not by Noam
-- Elkies in 1986. Elkies found the larger d = 20615673 identity.
UPDATE submissions
SET contributor_id = (SELECT id FROM contributors WHERE name = 'Roger Frye'),
    discovered_at = '1988-01-01T00:00:00Z'
WHERE id = 'seed-413-elkies';

-- MacLeod found this identity in 1997; 1998 is its publication year.
UPDATE submissions
SET discovered_at = '1997-01-01T00:00:00Z'
WHERE id = 'euler-413-638523249';

WITH incoming(id, contributor, left_terms, right_terms, discovered_at) AS (VALUES
  ('tomita-413-145087793', 'Juergen Rathmann',
   '[145087793]', '[122055375,121952168,1841160]', '2007-05-31T00:00:00Z'),
  ('tomita-413-156646737', 'Juergen Rathmann',
   '[156646737]', '[146627384,108644015,27450160]', '2007-06-01T00:00:00Z'),
  ('tomita-413-15434547801', 'Seiji Tomita',
   '[15434547801]', '[15355831360,5821981400,140976551]', '2007-10-24T00:00:00Z'),
  ('tomita-413-29999857938609', 'Seiji Tomita',
   '[29999857938609]', '[27239791692640,22495595284040,7592431981391]', '2006-03-13T00:00:00Z'),
  ('tomita-413-5062297699257', 'Seiji Tomita',
   '[5062297699257]', '[4987588419655,2480452675600,502038853976]', '2008-05-15T00:00:00Z'),
  ('tomita-413-573646321871961', 'Seiji Tomita',
   '[573646321871961]', '[514818101299289,440804942580160,130064300991400]', '2008-09-15T00:00:00Z')
)
INSERT INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT incoming.id, '4-1-3', contributor.id, incoming.left_terms,
       incoming.right_terms, NULL, incoming.discovered_at
FROM incoming
JOIN contributors AS contributor ON contributor.name = incoming.contributor;

-- Attach each correction to the source that supports it.
INSERT INTO submission_resources (submission_id, resource_id, role)
SELECT submission.id, resource.id, 'source'
FROM submissions AS submission
JOIN resources AS resource ON resource.url = 'http://euler.free.fr/details.htm'
WHERE submission.id IN ('euler-835-966', 'seed-413-elkies')
ON CONFLICT DO NOTHING;

INSERT INTO submission_resources (submission_id, resource_id, role)
SELECT submission.id, resource.id, 'source'
FROM submissions AS submission
JOIN resources AS resource
  ON resource.url = 'http://www.maroon.dti.ne.jp/fermat/dioph46e.html'
WHERE submission.id IN (
  'euler-413-2813001',
  'tomita-413-145087793',
  'tomita-413-156646737',
  'tomita-413-15434547801',
  'tomita-413-29999857938609',
  'tomita-413-5062297699257',
  'tomita-413-573646321871961'
)
ON CONFLICT DO NOTHING;

INSERT INTO submission_resources (submission_id, resource_id, role)
SELECT submission.id, resource.id, 'source'
FROM submissions AS submission
JOIN resources AS resource
  ON resource.url = 'https://cr.yp.to/papers/sortedsums-19990928-retypeset20220327.pdf'
WHERE submission.id IN (
  'euler-413-8707481',
  'euler-413-12197457',
  'euler-413-16003017',
  'euler-413-16430513'
)
ON CONFLICT DO NOTHING;

INSERT INTO submission_resources (submission_id, resource_id, role)
SELECT submission.id, resource.id, 'source'
FROM submissions AS submission
JOIN resources AS resource
  ON resource.url = 'https://mathworld.wolfram.com/DiophantineEquation4thPowers.html'
WHERE submission.id = 'euler-413-638523249'
ON CONFLICT DO NOTHING;
