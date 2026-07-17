-- Simon Goater's earlier fifth-power results were not produced with
-- JP_sieve. Retain the submissions themselves, but remove the incorrect tool
-- attribution from records predating July 10, 2026. The date condition keeps
-- this correction compatible with later records where the attribution may be
-- valid.

DELETE FROM submission_resources
WHERE role = 'tool'
  AND resource_id = (
    SELECT id
    FROM resources
    WHERE url = 'https://github.com/jorisperrenet/equal_sums_of_powers'
  )
  AND submission_id IN (
    SELECT submissions.id
    FROM submissions
    JOIN contributors ON contributors.id = submissions.contributor_id
    WHERE contributors.name = 'Simon Goater'
      AND submissions.discovered_at < '2026-07-10T00:00:00Z'
  );
