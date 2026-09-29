-- Category changes that need more than an INSERT.
--
-- (11, 1, 13) needs 13 terms on one side, beyond the original
-- CHECK (... BETWEEN 1 AND 12), so the categories table is first rebuilt with a
-- limit of 20 per side. SQLite cannot alter a CHECK in place.
--
-- The rebuild keeps every row and every link:
--   * Foreign keys are deferred, so submissions, search_claims and
--     target_coverage may point at the briefly absent table; they are checked
--     at commit, when the rebuilt table holds the same ids.
--   * DROP TABLE runs an implicit DELETE, which would cascade into
--     category_resources (ON DELETE CASCADE) and empty it, so those links are
--     copied aside first and restored afterwards.
--   * The table is recreated under its own name rather than renamed into
--     place, so the triggers and the view on other tables that name it stay
--     valid untouched.
--   * DROP TABLE also drops the site_version triggers that migration 0027
--     defined on categories; they are recreated below, before any change that
--     should bump the version.
PRAGMA defer_foreign_keys = true;

CREATE TABLE categories_backup AS SELECT * FROM categories;
CREATE TABLE category_resources_backup AS SELECT * FROM category_resources;

DROP TABLE categories;

CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  exponent INTEGER NOT NULL CHECK (exponent BETWEEN 2 AND 20),
  left_count INTEGER NOT NULL CHECK (left_count BETWEEN 1 AND 20),
  right_count INTEGER NOT NULL CHECK (right_count BETWEEN 1 AND 20),
  format TEXT NOT NULL CHECK (format IN ('equality', 'near_miss', 'target')),
  notation TEXT,
  submission_count INTEGER NOT NULL DEFAULT 0
);

INSERT INTO categories (id, exponent, left_count, right_count, format, notation, submission_count)
SELECT id, exponent, left_count, right_count, format, notation, submission_count
FROM categories_backup;

INSERT OR IGNORE INTO category_resources (category_id, resource_id)
SELECT category_id, resource_id FROM category_resources_backup;

DROP TABLE categories_backup;
DROP TABLE category_resources_backup;

CREATE TRIGGER site_version_after_categories_insert AFTER INSERT ON categories
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_categories_update AFTER UPDATE OF id, exponent, left_count, right_count, format, notation ON categories
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;
CREATE TRIGGER site_version_after_categories_delete AFTER DELETE ON categories
BEGIN UPDATE site_version SET version = version + 1 WHERE id = 1; END;

INSERT INTO categories (id, exponent, left_count, right_count, format, notation)
VALUES
  ('6-2-4', 6, 2, 4, 'equality', NULL),
  ('6-1-6', 6, 1, 6, 'equality', NULL),
  ('11-1-13', 11, 1, 13, 'equality', NULL);

-- (6, 4, 1; ±1) never received a result. The guard keeps it if one has
-- arrived since, rather than deleting data; category_resources rows go with it
-- through ON DELETE CASCADE.
DELETE FROM categories
WHERE id = '6-4-1-pm1'
  AND NOT EXISTS (SELECT 1 FROM submissions WHERE category_id = '6-4-1-pm1')
  AND NOT EXISTS (SELECT 1 FROM search_claims WHERE category_id = '6-4-1-pm1');
