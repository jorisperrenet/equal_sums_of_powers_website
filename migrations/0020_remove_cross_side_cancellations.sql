-- Remove equality and near-miss submissions with a nonzero base on both
-- sides. For near misses, the final right_terms value is the ±1 residual
-- and is deliberately excluded from the comparison.
DELETE FROM submissions
WHERE EXISTS (
  SELECT 1
  FROM categories AS category
  JOIN json_each(submissions.left_terms) AS left_term
  JOIN json_each(submissions.right_terms) AS right_term
  WHERE category.id = submissions.category_id
    AND category.format IN ('equality', 'near_miss')
    AND CAST(right_term.key AS INTEGER) < category.right_count
    AND CAST(left_term.value AS INTEGER) <> 0
    AND CAST(left_term.value AS INTEGER) = CAST(right_term.value AS INTEGER)
);
