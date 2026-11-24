-- Import the 28 primitive (6, 3, 4) solutions of
-- a1^6 + a2^6 + a3^6 = b1^6 + b2^6 + b3^6 + b4^6:
--   * 5 solutions from L. J. Lander, T. R. Parkin and J. L. Selfridge,
--     "A survey of equal sums of like powers", Math. Comp. 21 (July 1967),
--     446-459 (dated 1967-07-01).
--   * 23 solutions from R. L. Ekl, "New results in equal sums of like powers",
--     Math. Comp. 67 (July 1998), 1309-1315 (dated 1998-07-01).
--
-- Purely additive and guarded against duplicating any live submission via
-- identity_key. Every identity was verified with exact BigInt arithmetic, is
-- primitive, has positive terms with no cross-side cancellation, and stores
-- terms in descending order on each side.

INSERT OR IGNORE INTO contributors (name) VALUES
  ('L. J. Lander, T. R. Parkin and J. L. Selfridge'),
  ('Randy Ekl');

INSERT OR IGNORE INTO resources (title, url) VALUES
  (
    'Lander, Parkin and Selfridge: A survey of equal sums of like powers (Math. Comp. 1967)',
    'https://doi.org/10.1090/S0025-5718-1967-0222008-0'
  ),
  (
    'Ekl: New results in equal sums of like powers (Math. Comp. 1998)',
    'https://doi.org/10.1090/S0025-5718-98-00979-X'
  );

INSERT OR IGNORE INTO category_resources (category_id, resource_id)
SELECT '6-3-4', id
FROM resources
WHERE url IN (
  'https://doi.org/10.1090/S0025-5718-1967-0222008-0',
  'https://doi.org/10.1090/S0025-5718-98-00979-X'
);

CREATE TABLE import_6_3_4 (
  id TEXT PRIMARY KEY,
  contributor TEXT NOT NULL,
  left_terms TEXT NOT NULL,
  right_terms TEXT NOT NULL,
  discovered_at TEXT NOT NULL,
  identity_key TEXT NOT NULL,
  source_url TEXT NOT NULL
);

INSERT INTO import_6_3_4 VALUES
  -- Lander, Parkin and Selfridge (1967) — 5 solutions
  ('lps-634-73', 'L. J. Lander, T. R. Parkin and J. L. Selfridge', '[73,58,41]', '[70,65,32,15]', '1967-07-01T00:00:00Z', '73,58,41=70,65,32,15', 'https://doi.org/10.1090/S0025-5718-1967-0222008-0'),
  ('lps-634-85', 'L. J. Lander, T. R. Parkin and J. L. Selfridge', '[85,62,61]', '[83,69,56,52]', '1967-07-01T00:00:00Z', '85,62,61=83,69,56,52', 'https://doi.org/10.1090/S0025-5718-1967-0222008-0'),
  ('lps-634-87', 'L. J. Lander, T. R. Parkin and J. L. Selfridge', '[85,74,61]', '[87,71,56,26]', '1967-07-01T00:00:00Z', '85,74,61=87,71,56,26', 'https://doi.org/10.1090/S0025-5718-1967-0222008-0'),
  ('lps-634-92', 'L. J. Lander, T. R. Parkin and J. L. Selfridge', '[90,88,11]', '[92,78,74,21]', '1967-07-01T00:00:00Z', '90,88,11=92,78,74,21', 'https://doi.org/10.1090/S0025-5718-1967-0222008-0'),
  ('lps-634-101', 'L. J. Lander, T. R. Parkin and J. L. Selfridge', '[95,83,26]', '[101,28,24,23]', '1967-07-01T00:00:00Z', '95,83,26=101,28,24,23', 'https://doi.org/10.1090/S0025-5718-1967-0222008-0'),
  -- Ekl (1998) — 23 solutions
  ('ekl-634-130', 'Randy Ekl', '[130,44,23]', '[119,108,86,38]', '1998-07-01T00:00:00Z', '130,44,23=119,108,86,38', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-126', 'Randy Ekl', '[125,114,38]', '[126,104,93,68]', '1998-07-01T00:00:00Z', '125,114,38=126,104,93,68', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-205', 'Randy Ekl', '[205,113,18]', '[198,148,133,39]', '1998-07-01T00:00:00Z', '205,113,18=198,148,133,39', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-211', 'Randy Ekl', '[211,123,34]', '[210,134,73,39]', '1998-07-01T00:00:00Z', '211,123,34=210,134,73,39', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-217', 'Randy Ekl', '[212,164,103]', '[217,130,114,8]', '1998-07-01T00:00:00Z', '212,164,103=217,130,114,8', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-222', 'Randy Ekl', '[222,34,25]', '[217,156,96,68]', '1998-07-01T00:00:00Z', '222,34,25=217,156,96,68', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-224', 'Randy Ekl', '[218,167,29]', '[224,107,102,65]', '1998-07-01T00:00:00Z', '218,167,29=224,107,102,65', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-226', 'Randy Ekl', '[226,110,17]', '[224,143,72,34]', '1998-07-01T00:00:00Z', '226,110,17=224,143,72,34', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-244', 'Randy Ekl', '[244,123,112]', '[238,180,91,72]', '1998-07-01T00:00:00Z', '244,123,112=238,180,91,72', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-246', 'Randy Ekl', '[241,172,156]', '[246,145,132,56]', '1998-07-01T00:00:00Z', '241,172,156=246,145,132,56', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-257', 'Randy Ekl', '[257,155,6]', '[252,181,143,114]', '1998-07-01T00:00:00Z', '257,155,6=252,181,143,114', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-265', 'Randy Ekl', '[265,147,12]', '[231,221,210,114]', '1998-07-01T00:00:00Z', '265,147,12=231,221,210,114', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-276', 'Randy Ekl', '[260,218,185]', '[276,152,112,25]', '1998-07-01T00:00:00Z', '260,218,185=276,152,112,25', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-305', 'Randy Ekl', '[305,85,66]', '[273,267,172,122]', '1998-07-01T00:00:00Z', '305,85,66=273,267,172,122', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-315', 'Randy Ekl', '[312,241,33]', '[315,228,99,2]', '1998-07-01T00:00:00Z', '312,241,33=315,228,99,2', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-331', 'Randy Ekl', '[331,234,59]', '[306,294,151,95]', '1998-07-01T00:00:00Z', '331,234,59=306,294,151,95', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-338', 'Randy Ekl', '[332,243,43]', '[338,177,168,95]', '1998-07-01T00:00:00Z', '332,243,43=338,177,168,95', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-351', 'Randy Ekl', '[351,265,221]', '[336,309,169,73]', '1998-07-01T00:00:00Z', '351,265,221=336,309,169,73', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-365', 'Randy Ekl', '[365,137,126]', '[360,234,175,133]', '1998-07-01T00:00:00Z', '365,137,126=360,234,175,133', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-360', 'Randy Ekl', '[360,265,200]', '[336,318,212,169]', '1998-07-01T00:00:00Z', '360,265,200=336,318,212,169', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-357', 'Randy Ekl', '[348,325,36]', '[357,276,276,82]', '1998-07-01T00:00:00Z', '348,325,36=357,276,276,82', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-373', 'Randy Ekl', '[373,288,104]', '[363,292,266,120]', '1998-07-01T00:00:00Z', '373,288,104=363,292,266,120', 'https://doi.org/10.1090/S0025-5718-98-00979-X'),
  ('ekl-634-386', 'Randy Ekl', '[386,113,62]', '[378,260,209,88]', '1998-07-01T00:00:00Z', '386,113,62=378,260,209,88', 'https://doi.org/10.1090/S0025-5718-98-00979-X');

INSERT INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT i.id, '6-3-4', c.id, i.left_terms, i.right_terms, NULL, i.discovered_at
FROM import_6_3_4 i
JOIN contributors c ON c.name = i.contributor
WHERE NOT EXISTS (
  SELECT 1 FROM submissions s
  WHERE s.category_id = '6-3-4' AND s.identity_key = i.identity_key
);

INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT s.id, r.id, 'source'
FROM submissions s
JOIN import_6_3_4 i ON s.category_id = '6-3-4' AND s.identity_key = i.identity_key
JOIN resources r ON r.url = i.source_url;

DROP TABLE import_6_3_4;
