-- A data version for the page cache (src/lib/server/cache.ts). Cached query
-- results are keyed by it, so every change to data the site displays must bump
-- it; entries for older versions are then never requested again.
--
-- Triggers cover every table the site reads. Derived tables (target_coverage,
-- resource_submission_counts) change only alongside a change here. The
-- trigger-maintained columns submissions.max_term, submissions.identity_key and
-- categories.submission_count are left out of the UPDATE triggers, so filling
-- them in bumps nothing. (Normalizing discovered_at right after an insert
-- does bump a second time, in the same statement.) Purely additive.
CREATE TABLE site_version (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  version INTEGER NOT NULL
);

INSERT INTO site_version (id, version) VALUES (1, 1);

CREATE TRIGGER site_version_after_submissions_insert AFTER INSERT ON submissions
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_submissions_update AFTER UPDATE OF category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at ON submissions
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_submissions_delete AFTER DELETE ON submissions
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;

CREATE TRIGGER site_version_after_submission_resources_insert AFTER INSERT ON submission_resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_submission_resources_update AFTER UPDATE ON submission_resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_submission_resources_delete AFTER DELETE ON submission_resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;

CREATE TRIGGER site_version_after_resources_insert AFTER INSERT ON resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_resources_update AFTER UPDATE ON resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_resources_delete AFTER DELETE ON resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;

CREATE TRIGGER site_version_after_contributors_insert AFTER INSERT ON contributors
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_contributors_update AFTER UPDATE ON contributors
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_contributors_delete AFTER DELETE ON contributors
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;

CREATE TRIGGER site_version_after_categories_insert AFTER INSERT ON categories
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_categories_update AFTER UPDATE OF id, exponent, left_count, right_count, format, notation ON categories
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_categories_delete AFTER DELETE ON categories
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;

CREATE TRIGGER site_version_after_category_resources_insert AFTER INSERT ON category_resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_category_resources_update AFTER UPDATE ON category_resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_category_resources_delete AFTER DELETE ON category_resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;

CREATE TRIGGER site_version_after_search_claims_insert AFTER INSERT ON search_claims
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_search_claims_update AFTER UPDATE ON search_claims
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_search_claims_delete AFTER DELETE ON search_claims
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;

CREATE TRIGGER site_version_after_search_claim_resources_insert AFTER INSERT ON search_claim_resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_search_claim_resources_update AFTER UPDATE ON search_claim_resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_search_claim_resources_delete AFTER DELETE ON search_claim_resources
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
