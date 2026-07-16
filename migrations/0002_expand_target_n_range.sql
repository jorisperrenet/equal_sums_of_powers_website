DROP TRIGGER submissions_target_n_bounds;

CREATE TRIGGER submissions_target_n_bounds
BEFORE INSERT ON submissions
WHEN NEW.category_id = '5-5-n' AND (
  CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER) < -1000 OR
  CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER) > 2500
)
BEGIN
  SELECT RAISE(ABORT, 'N must be between -1000 and 2500');
END;
