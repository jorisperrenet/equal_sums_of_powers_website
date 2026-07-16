DELETE FROM category_resources
WHERE category_id = '7-3-4';

DELETE FROM categories
WHERE id = '7-3-4';

INSERT INTO categories (id, exponent, left_count, right_count, format, notation)
VALUES
  ('7-7-n', 7, 7, 1, 'target', '(7, 7; N)'),
  ('9-9-n', 9, 9, 1, 'target', '(9, 9; N)');

DROP TRIGGER submissions_target_n_bounds;

CREATE TRIGGER submissions_target_n_bounds
BEFORE INSERT ON submissions
WHEN EXISTS (
  SELECT 1
  FROM categories
  WHERE id = NEW.category_id AND format = 'target'
) AND (
  CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER) < -1000 OR
  CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER) > 2500
)
BEGIN
  SELECT RAISE(ABORT, 'N must be between -1000 and 2500');
END;
