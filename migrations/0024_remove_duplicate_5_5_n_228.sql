-- The (5, 5; 228) solution 52101^5 - 48992^5 - 39829^5 - 17029^5 - 5303^5 = 228
-- exists twice: once imported by migration 0007 as 'simon-goater-5-5-n-228' with
-- the terms in non-canonical order, and once submitted through the site as
-- 563356ca-bfd8-4f4c-84d1-54a76fbd5a10 in canonical order. The two JSON strings
-- differ, so UNIQUE(category_id, left_terms, right_terms) did not catch it.
--
-- Keep the canonical row, move the imported row's source citation onto it, and
-- remove the imported row. Every statement is guarded on the canonical row being
-- present, so a database without it (for example a local copy built from the
-- migrations alone) keeps the imported row as its only copy of the solution.
-- The triggers from migration 0023 correct categories.submission_count and the
-- target_coverage entry for N = 228 automatically.

INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT '563356ca-bfd8-4f4c-84d1-54a76fbd5a10', resource_id, role
FROM submission_resources
WHERE submission_id = 'simon-goater-5-5-n-228'
  AND EXISTS (
    SELECT 1 FROM submissions
    WHERE id = '563356ca-bfd8-4f4c-84d1-54a76fbd5a10'
      AND category_id = '5-5-n'
      AND left_terms = '[52101,-48992,-39829,-17029,-5303]'
      AND right_terms = '[228]'
  );

DELETE FROM submission_resources
WHERE submission_id = 'simon-goater-5-5-n-228'
  AND EXISTS (
    SELECT 1 FROM submissions
    WHERE id = '563356ca-bfd8-4f4c-84d1-54a76fbd5a10'
      AND category_id = '5-5-n'
      AND left_terms = '[52101,-48992,-39829,-17029,-5303]'
      AND right_terms = '[228]'
  );

DELETE FROM submissions
WHERE id = 'simon-goater-5-5-n-228'
  AND EXISTS (
    SELECT 1 FROM submissions
    WHERE id = '563356ca-bfd8-4f4c-84d1-54a76fbd5a10'
      AND category_id = '5-5-n'
      AND left_terms = '[52101,-48992,-39829,-17029,-5303]'
      AND right_terms = '[228]'
  );
