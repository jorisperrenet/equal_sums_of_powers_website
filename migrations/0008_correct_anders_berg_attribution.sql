-- The July 14 (7, 4, 4) continuation post was authored by Anders Berg.
-- Keep the legacy submission IDs stable, but correct the displayed contributor.

INSERT OR IGNORE INTO contributors (name) VALUES ('Anders Berg');

UPDATE submissions
SET contributor_id = (SELECT id FROM contributors WHERE name = 'Anders Berg')
WHERE id IN (
  'mse-5143215-dm-5065-3439',
  'mse-5143215-dm-5080-2809',
  'mse-5143215-dm-5103-2908',
  'mse-5143215-dm-5176-4001',
  'mse-5143215-dm-5203-4874',
  'mse-5143215-dm-5355-4658',
  'mse-5143215-dm-5971-3961',
  'mse-5143215-dm-6026-3456',
  'mse-5143215-dm-6094-5981',
  'mse-5143215-dm-6454-1379',
  'mse-5143215-dm-6606-2950',
  'mse-5143215-dm-6737-3994'
);

UPDATE search_claims
SET contributor_id = (SELECT id FROM contributors WHERE name = 'Anders Berg')
WHERE id = 'mse-5143215-dm-radius-7000';
