-- These four equality identities are represented by their equivalent
-- (5, 5; 0) target rows as of migration 0014, so the separate equality
-- categories and their duplicate records are no longer needed.

DELETE FROM search_claims
WHERE category_id IN ('5-4-1', '5-3-2');

DELETE FROM submissions
WHERE category_id IN ('5-4-1', '5-3-2');

DELETE FROM categories
WHERE id IN ('5-4-1', '5-3-2');
