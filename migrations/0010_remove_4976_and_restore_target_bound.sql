-- N=4976 is outside the public (5, 5; N) archive range.
DELETE FROM submissions
WHERE id = 'mse-5116554-danielv-4976';

DELETE FROM resources
WHERE url = 'https://play.rust-lang.org/?edition=2024&gist=97684d4abab5935a2a920144f9233af2&mode=release&version=stable'
  AND NOT EXISTS (
    SELECT 1 FROM submission_resources
    WHERE resource_id = resources.id
  )
  AND NOT EXISTS (
    SELECT 1 FROM search_claim_resources
    WHERE resource_id = resources.id
  )
  AND NOT EXISTS (
    SELECT 1 FROM category_resources
    WHERE resource_id = resources.id
  );

DROP TRIGGER submissions_target_n_bounds;

CREATE TRIGGER submissions_target_n_bounds
BEFORE INSERT ON submissions
WHEN EXISTS (
  SELECT 1
  FROM categories
  WHERE id = NEW.category_id AND format = 'target'
) AND (
  CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER) < 0 OR
  CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER) > 2500
)
BEGIN
  SELECT RAISE(ABORT, 'N must be between 0 and 2500');
END;
