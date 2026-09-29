-- New empty categories, oriented like the existing ones (fewer terms on the
-- left). Purely additive: submission counts and target coverage are kept by
-- the triggers of migration 0023. (11, 1, 13) follows in migration 0028, which
-- first lifts the 12-terms-per-side limit.
INSERT INTO categories (id, exponent, left_count, right_count, format, notation)
VALUES
  ('8-4-5', 8, 4, 5, 'equality', NULL),
  ('8-3-6', 8, 3, 6, 'equality', NULL),
  ('8-2-7', 8, 2, 7, 'equality', NULL),
  ('8-1-8', 8, 1, 8, 'equality', NULL),
  ('10-6-6', 10, 6, 6, 'equality', NULL),
  ('10-5-7', 10, 5, 7, 'equality', NULL),
  ('10-4-8', 10, 4, 8, 'equality', NULL),
  ('10-3-9', 10, 3, 9, 'equality', NULL),
  ('10-2-10', 10, 2, 10, 'equality', NULL),
  ('10-1-11', 10, 1, 11, 'equality', NULL),
  ('10-5-6', 10, 5, 6, 'equality', NULL),
  ('10-4-7', 10, 4, 7, 'equality', NULL),
  ('10-3-8', 10, 3, 8, 'equality', NULL),
  ('10-2-9', 10, 2, 9, 'equality', NULL),
  ('10-1-10', 10, 1, 10, 'equality', NULL),
  ('11-7-7', 11, 7, 7, 'equality', NULL),
  ('11-6-8', 11, 6, 8, 'equality', NULL),
  ('11-5-9', 11, 5, 9, 'equality', NULL),
  ('11-4-10', 11, 4, 10, 'equality', NULL),
  ('11-3-11', 11, 3, 11, 'equality', NULL),
  ('11-2-12', 11, 2, 12, 'equality', NULL),
  ('11-11-n', 11, 11, 1, 'target', '(11, 11; N)');
