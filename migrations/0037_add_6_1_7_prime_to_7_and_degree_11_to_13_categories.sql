-- New categories. Purely additive: submission counts, target coverage and the
-- site version are kept by the triggers of migrations 0023 and 0027.
--
-- 1. (6, 1, 7; 7 ∤ a): solutions of a^6 = b1^6 + ... + b7^6 whose lone term a is
--    not divisible by 7. Like (4, 1, 4), the category records only solutions
--    meeting an extra condition; src/lib/category-conditions.ts enforces it on
--    submission and scripts/check-database.mjs audits it. Most known (6, 1, 7)
--    solutions have 7 | a. The id leaves '6-1-7' free for an unrestricted
--    category later.
--
-- 2. Higher degrees, oriented like the existing ones (fewer terms on the left),
--    with every split of each total:
--      11th powers, 13 terms (11th powers so far had 14 terms only)
--      12th powers, 14, 15 and 16 terms
--      13th powers, 16, 17 and 18 terms
INSERT INTO categories (id, exponent, left_count, right_count, format, notation)
VALUES
  ('6-1-7-coprime-7', 6, 1, 7, 'equality', '(6, 1, 7; 7 ∤ a)'),
  ('11-6-7', 11, 6, 7, 'equality', NULL),
  ('11-5-8', 11, 5, 8, 'equality', NULL),
  ('11-4-9', 11, 4, 9, 'equality', NULL),
  ('11-3-10', 11, 3, 10, 'equality', NULL),
  ('11-2-11', 11, 2, 11, 'equality', NULL),
  ('11-1-12', 11, 1, 12, 'equality', NULL),
  ('12-7-7', 12, 7, 7, 'equality', NULL),
  ('12-6-8', 12, 6, 8, 'equality', NULL),
  ('12-5-9', 12, 5, 9, 'equality', NULL),
  ('12-4-10', 12, 4, 10, 'equality', NULL),
  ('12-3-11', 12, 3, 11, 'equality', NULL),
  ('12-2-12', 12, 2, 12, 'equality', NULL),
  ('12-1-13', 12, 1, 13, 'equality', NULL),
  ('12-7-8', 12, 7, 8, 'equality', NULL),
  ('12-6-9', 12, 6, 9, 'equality', NULL),
  ('12-5-10', 12, 5, 10, 'equality', NULL),
  ('12-4-11', 12, 4, 11, 'equality', NULL),
  ('12-3-12', 12, 3, 12, 'equality', NULL),
  ('12-2-13', 12, 2, 13, 'equality', NULL),
  ('12-1-14', 12, 1, 14, 'equality', NULL),
  ('12-8-8', 12, 8, 8, 'equality', NULL),
  ('12-7-9', 12, 7, 9, 'equality', NULL),
  ('12-6-10', 12, 6, 10, 'equality', NULL),
  ('12-5-11', 12, 5, 11, 'equality', NULL),
  ('12-4-12', 12, 4, 12, 'equality', NULL),
  ('12-3-13', 12, 3, 13, 'equality', NULL),
  ('12-2-14', 12, 2, 14, 'equality', NULL),
  ('12-1-15', 12, 1, 15, 'equality', NULL),
  ('13-8-8', 13, 8, 8, 'equality', NULL),
  ('13-7-9', 13, 7, 9, 'equality', NULL),
  ('13-6-10', 13, 6, 10, 'equality', NULL),
  ('13-5-11', 13, 5, 11, 'equality', NULL),
  ('13-4-12', 13, 4, 12, 'equality', NULL),
  ('13-3-13', 13, 3, 13, 'equality', NULL),
  ('13-2-14', 13, 2, 14, 'equality', NULL),
  ('13-1-15', 13, 1, 15, 'equality', NULL),
  ('13-8-9', 13, 8, 9, 'equality', NULL),
  ('13-7-10', 13, 7, 10, 'equality', NULL),
  ('13-6-11', 13, 6, 11, 'equality', NULL),
  ('13-5-12', 13, 5, 12, 'equality', NULL),
  ('13-4-13', 13, 4, 13, 'equality', NULL),
  ('13-3-14', 13, 3, 14, 'equality', NULL),
  ('13-2-15', 13, 2, 15, 'equality', NULL),
  ('13-1-16', 13, 1, 16, 'equality', NULL),
  ('13-9-9', 13, 9, 9, 'equality', NULL),
  ('13-8-10', 13, 8, 10, 'equality', NULL),
  ('13-7-11', 13, 7, 11, 'equality', NULL),
  ('13-6-12', 13, 6, 12, 'equality', NULL),
  ('13-5-13', 13, 5, 13, 'equality', NULL),
  ('13-4-14', 13, 4, 14, 'equality', NULL),
  ('13-3-15', 13, 3, 15, 'equality', NULL),
  ('13-2-16', 13, 2, 16, 'equality', NULL),
  ('13-1-17', 13, 1, 17, 'equality', NULL);
