-- Retain the 20 newest coverage claims if an imported database already
-- exceeds the cap, then enforce the global limit for every future writer.
DELETE FROM search_claims
WHERE id NOT IN (
  SELECT id
  FROM search_claims
  ORDER BY created_at DESC, id DESC
  LIMIT 20
);

CREATE TRIGGER search_claims_maximum_rows
BEFORE INSERT ON search_claims
WHEN (SELECT COUNT(*) FROM search_claims) >= 20
BEGIN
  SELECT RAISE(ABORT, 'search coverage limit reached');
END;
