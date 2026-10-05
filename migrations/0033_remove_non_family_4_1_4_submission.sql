-- (4, 1, 4) records only solutions with e = a + k³(b + c + d) for a rational k
-- (migration 0030). One submission without such a k was accepted on
-- 2026-10-05, before the site enforced that: Norrie's smallest solution,
-- 353^4 = 315^4 + 272^4 + 120^4 + 30^4. This removes that row only. The guards
-- keep any other row, and this one if it has gained a k. Its resource links go
-- with it through ON DELETE CASCADE, and the triggers from migrations 0023,
-- 0025 and 0027 update the category count, citation counts and data version.
DELETE FROM submissions
WHERE id = 'f3b7bd00-bd0b-4c3b-8f23-d0870f0e42df'
  AND category_id = '4-1-4'
  AND family_k IS NULL
  AND identity_key = '353=315,272,120,30';
