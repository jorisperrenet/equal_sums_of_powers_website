-- A signed target containing both x and -x is a lower-term identity padded
-- with a cancelling pair, rather than a genuine solution in this category.
DELETE FROM submissions
WHERE category_id IN (
  SELECT id FROM categories WHERE format = 'target'
)
AND EXISTS (
  SELECT 1
  FROM json_each(submissions.left_terms) AS positive
  JOIN json_each(submissions.left_terms) AS negative
    ON CAST(negative.value AS INTEGER) = -CAST(positive.value AS INTEGER)
   AND negative.key <> positive.key
  WHERE CAST(positive.value AS INTEGER) <> 0
);
