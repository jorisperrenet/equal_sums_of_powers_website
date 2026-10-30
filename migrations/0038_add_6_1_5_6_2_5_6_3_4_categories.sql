-- New empty sixth-power categories, oriented like the existing ones (fewer
-- terms on the left): (6, 1, 5) joins the 6-term line, (6, 2, 5) and (6, 3, 4)
-- the 7-term line. Purely additive: submission counts and the site version
-- are kept by the triggers of migrations 0023 and 0027.
INSERT INTO categories (id, exponent, left_count, right_count, format, notation)
VALUES
  ('6-3-4', 6, 3, 4, 'equality', NULL),
  ('6-2-5', 6, 2, 5, 'equality', NULL),
  ('6-1-5', 6, 1, 5, 'equality', NULL);
