INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT submission.id, resource.id, 'tool'
FROM submissions submission
JOIN contributors contributor ON contributor.id = submission.contributor_id
JOIN resources resource
  ON resource.url = 'https://github.com/jorisperrenet/equal_sums_of_powers'
WHERE contributor.name = 'Joris Perrenet';

INSERT OR IGNORE INTO search_claim_resources (search_claim_id, resource_id)
SELECT claim.id, resource.id
FROM search_claims claim
JOIN contributors contributor ON contributor.id = claim.contributor_id
JOIN resources resource
  ON resource.url = 'https://github.com/jorisperrenet/equal_sums_of_powers'
WHERE contributor.name = 'Joris Perrenet';
