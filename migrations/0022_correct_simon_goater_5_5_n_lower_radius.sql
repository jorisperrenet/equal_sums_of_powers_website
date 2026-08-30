-- Simon Goater entered his (5, 5; N) search coverage with a lower radius of 1
-- by mistake; the search actually starts from 0. Amend 1 <= |x_i| to 0 <= |x_i|.
UPDATE search_claims
SET lower_radius = '0'
WHERE category_id = '5-5-n'
  AND contributor_id = (SELECT id FROM contributors WHERE name = 'Simon Goater')
  AND lower_radius = '1'
  AND upper_radius = '100000';
