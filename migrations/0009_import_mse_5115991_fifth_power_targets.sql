-- Verified fifth-power targets collected on MSE question 5115991. Rows that
-- already exist under another source are linked below instead of duplicated.

INSERT OR IGNORE INTO contributors (name) VALUES ('ydd');
INSERT OR IGNORE INTO contributors (name) VALUES ('user1762615');

INSERT OR IGNORE INTO resources (title, url) VALUES (
  'MSE: Can 2025 and 2026 be written as sums of five fifth powers?',
  'https://math.stackexchange.com/questions/5115991/can-2025-and-2026-be-written-as-sums-of-five-fifth-powers'
);

INSERT OR IGNORE INTO resources (title, url) VALUES (
  'DanielV fifth-power search example',
  'https://play.rust-lang.org/?edition=2024&gist=97684d4abab5935a2a920144f9233af2&mode=release&version=stable'
);

INSERT OR IGNORE INTO resources (title, url) VALUES (
  'DanielV fifth-power range search',
  'https://play.rust-lang.org/?edition=2024&gist=677b4d936bbea05a41b812c22a881a64&mode=release&version=stable'
);

INSERT OR IGNORE INTO resources (title, url) VALUES (
  'ydd Mathematica notebook for 2025 and 2026',
  'https://www.wolframcloud.com/obj/bb76659c-e970-4ade-bc3e-733c7214002e'
);

-- The answer includes a worked N=4976 example, so extend the public target
-- archive to the next round bound before inserting it.
DROP TRIGGER submissions_target_n_bounds;

CREATE TRIGGER submissions_target_n_bounds
BEFORE INSERT ON submissions
WHEN EXISTS (
  SELECT 1
  FROM categories
  WHERE id = NEW.category_id AND format = 'target'
) AND (
  CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER) < 0 OR
  CAST(json_extract(NEW.right_terms, '$[0]') AS INTEGER) > 5000
)
BEGIN
  SELECT RAISE(ABORT, 'N must be between 0 and 5000');
END;

-- Community-wiki answer 5116275. Unlabelled results are credited to the
-- answer's principal author, mezzoctane; explicitly named finders are kept.
WITH incoming(id, contributor, left_terms, target, discovered_at) AS (VALUES
  ('mse-5116275-mezzoctane-2017-4', 'mezzoctane', '[4,4,1,0,-2]', 2017, '2025-12-23T04:16:00Z'),
  ('mse-5116275-mezzoctane-2018-4', 'mezzoctane', '[4,4,1,1,-2]', 2018, '2025-12-23T04:16:00Z'),
  ('mse-5116275-mezzoctane-2018-17', 'mezzoctane', '[15,15,5,-10,-17]', 2018, '2025-12-23T04:16:00Z'),
  ('mse-5116275-guruprasad-2021', 'Guruprasad', '[140,1502,-1038,-1190,-1323]', 2021, '2026-03-11T01:51:27Z'),
  ('mse-5116275-mezzoctane-2023-74', 'mezzoctane', '[74,7,-30,-61,-67]', 2023, '2025-12-23T04:16:00Z'),
  ('mse-5116275-mezzoctane-2023-417', 'mezzoctane', '[382,339,24,-75,-417]', 2023, '2026-01-28T00:00:00Z'),
  ('mse-5116275-mezzoctane-2024-253', 'mezzoctane', '[247,173,-86,-127,-253]', 2024, '2025-12-23T04:16:00Z'),
  ('mse-5116275-simon-2024-4025', 'Simon Goater', '[4025,1994,1914,-2554,-3985]', 2024, '2026-07-14T00:00:00Z'),
  ('mse-5116275-ydd-2025', 'ydd', '[100,51,44,11,-101]', 2025, '2025-12-23T04:16:00Z'),
  ('mse-5116275-mezzoctane-2025-832', 'mezzoctane', '[832,60,-184,-471,-822]', 2025, '2026-01-28T00:00:00Z'),
  ('mse-5116275-mezzoctane-2025-1283', 'mezzoctane', '[1255,888,456,-731,-1283]', 2025, '2026-02-20T00:00:00Z'),
  ('mse-5116275-simon-2025-3397', 'Simon Goater', '[3397,1555,-975,-1945,-3367]', 2025, '2026-07-14T00:00:00Z'),
  ('mse-5116275-simon-2025-9142', 'Simon Goater', '[9142,-3405,-5092,-6249,-8721]', 2025, '2026-07-14T00:00:00Z'),
  ('mse-5116275-simon-2025-21825', 'Simon Goater', '[21825,-521,-5903,-12504,-21542]', 2025, '2026-07-14T00:00:00Z'),
  ('mse-5116275-simon-2025-27607', 'Simon Goater', '[26230,18822,16592,-1202,-27607]', 2025, '2026-07-14T00:00:00Z'),
  ('mse-5116275-simon-2025-41525', 'Simon Goater', '[40531,27294,792,-16037,-41525]', 2025, '2026-07-14T00:00:00Z'),
  ('mse-5116275-simon-2025-41464', 'Simon Goater', '[41464,37187,-14229,-37920,-40917]', 2025, '2026-07-14T00:00:00Z'),
  ('mse-5116275-ydd-2026', 'ydd', '[121,28,4,-79,-118]', 2026, '2025-12-23T04:16:00Z'),
  ('mse-5116275-simon-2026-2070', 'Simon Goater', '[2008,1417,-319,-810,-2070]', 2026, '2026-07-14T00:00:00Z'),
  ('mse-5116275-simon-2026-34322', 'Simon Goater', '[30316,27911,21939,-2688,-34322]', 2026, '2026-07-14T00:00:00Z'),
  ('mse-5116275-mezzoctane-2027-345', 'mezzoctane', '[345,41,-161,-299,-299]', 2027, '2025-12-26T06:41:00Z'),
  ('mse-5116275-simon-2027-5757', 'Simon Goater', '[5757,-129,-2460,-2974,-5697]', 2027, '2026-07-14T00:00:00Z'),
  ('mse-5116275-simon-2027-12264', 'Simon Goater', '[12101,7093,-623,-740,-12264]', 2027, '2026-07-14T00:00:00Z'),
  ('mse-5116275-simon-2027-37129', 'Simon Goater', '[37129,21221,-6915,-21524,-37094]', 2027, '2026-07-14T00:00:00Z')
)
INSERT INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT incoming.id, '5-5-n', contributors.id, incoming.left_terms,
       json_array(incoming.target), NULL, incoming.discovered_at
FROM incoming
JOIN contributors ON contributors.name = incoming.contributor;

-- Answer 5139375 by user1762615.
WITH incoming(id, left_terms, target) AS (VALUES
  ('mse-5139375-user1762615-2011', '[-456,-418,-116,692,-661]', 2011),
  ('mse-5139375-user1762615-2032', '[-520,-85,310,645,-598]', 2032),
  ('mse-5139375-user1762615-2055', '[-375,-123,-55,494,-466]', 2055),
  ('mse-5139375-user1762615-2059', '[-616,-275,-167,918,-891]', 2059),
  ('mse-5139375-user1762615-2076', '[-111,61,268,607,-609]', 2076),
  ('mse-5139375-user1762615-2100', '[-837,-115,317,846,-481]', 2100)
)
INSERT INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT incoming.id, '5-5-n', contributors.id, incoming.left_terms,
       json_array(incoming.target), NULL, '2026-06-04T03:18:00Z'
FROM incoming
JOIN contributors ON contributors.name = 'user1762615';

-- Answer 5116554 by DanielV. The non-primitive N=0, N=2048, and N=2080
-- equalities are omitted, as are seven rows represented above and five
-- existing identities.
WITH incoming(id, left_terms, target) AS (VALUES
  ('mse-5116554-danielv-4976', '[12,11,-7,-7,-13]', 4976),
  ('mse-5116554-danielv-1', '[-312,360,-360,1,312]', 1),
  ('mse-5116554-danielv-2', '[-167,1,0,1,167]', 2),
  ('mse-5116554-danielv-3', '[1,315,-315,1,1]', 3),
  ('mse-5116554-danielv-4', '[0,1,1,1,1]', 4),
  ('mse-5116554-danielv-5', '[1,1,1,1,1]', 5),
  ('mse-5116554-danielv-11', '[-17,-1,0,13,16]', 11),
  ('mse-5116554-danielv-12', '[-167,16,-17,13,167]', 12),
  ('mse-5116554-danielv-13', '[-17,13,0,1,16]', 13),
  ('mse-5116554-danielv-14', '[-17,1,1,13,16]', 14),
  ('mse-5116554-danielv-17', '[-1,13,-15,7,13]', 17),
  ('mse-5116554-danielv-19', '[-15,7,1,13,13]', 19),
  ('mse-5116554-danielv-20', '[46,55,-59,-15,23]', 20),
  ('mse-5116554-danielv-21', '[153,271,-274,-64,-35]', 21),
  ('mse-5116554-danielv-22', '[79,118,-121,-28,4]', 22),
  ('mse-5116554-danielv-23', '[78,129,-131,-30,-23]', 23),
  ('mse-5116554-danielv-25', '[31,67,-60,-57,14]', 25),
  ('mse-5116554-danielv-28', '[-1,-1,-1,-1,2]', 28),
  ('mse-5116554-danielv-29', '[-1,2,-1,-1,0]', 29),
  ('mse-5116554-danielv-30', '[-1,0,-1,0,2]', 30),
  ('mse-5116554-danielv-31', '[-1,315,-315,0,2]', 31),
  ('mse-5116554-danielv-32', '[0,317,-317,0,2]', 32),
  ('mse-5116554-danielv-33', '[1,261,-261,0,2]', 33),
  ('mse-5116554-danielv-34', '[-242,2,1,1,242]', 34),
  ('mse-5116554-danielv-35', '[0,2,1,1,1]', 35),
  ('mse-5116554-danielv-36', '[-182,64,-140,-109,193]', 36),
  ('mse-5116554-danielv-43', '[-306,95,-254,185,323]', 43),
  ('mse-5116554-danielv-44', '[18,110,-104,-83,-17]', 44),
  ('mse-5116554-danielv-45', '[-17,2,1,13,16]', 45),
  ('mse-5116554-danielv-46', '[9,10,-11,4,4]', 46),
  ('mse-5116554-danielv-47', '[75,124,-126,-41,45]', 47),
  ('mse-5116554-danielv-50', '[-15,7,2,13,13]', 50),
  ('mse-5116554-danielv-2000', '[-172,55,-103,138,162]', 2000),
  ('mse-5116554-danielv-2001', '[-9,-1,-10,0,11]', 2001),
  ('mse-5116554-danielv-2002', '[-10,-1,-9,1,11]', 2002),
  ('mse-5116554-danielv-2003', '[-10,-9,0,1,11]', 2003),
  ('mse-5116554-danielv-2004', '[-10,1,-9,1,11]', 2004),
  ('mse-5116554-danielv-2005', '[-2,5,-4,-2,-2]', 2005),
  ('mse-5116554-danielv-2006', '[-21,34,-30,-28,11]', 2006),
  ('mse-5116554-danielv-2010', '[-214,142,-9,115,206]', 2010),
  ('mse-5116554-danielv-2012', '[3,6,-5,-5,3]', 2012),
  ('mse-5116554-danielv-2014', '[4,4,-2,-1,-1]', 2014),
  ('mse-5116554-danielv-2015', '[-2,-1,0,4,4]', 2015),
  ('mse-5116554-danielv-2016', '[-167,4,-2,4,167]', 2016),
  ('mse-5116554-danielv-2033', '[-10,-1,-9,2,11]', 2033),
  ('mse-5116554-danielv-2034', '[-10,11,-9,0,2]', 2034),
  ('mse-5116554-danielv-2035', '[-10,11,-9,1,2]', 2035),
  ('mse-5116554-danielv-2036', '[-2,-1,-4,-2,5]', 2036),
  ('mse-5116554-danielv-2037', '[-2,5,-4,-2,0]', 2037),
  ('mse-5116554-danielv-2038', '[-2,-2,-4,1,5]', 2038),
  ('mse-5116554-danielv-2043', '[-150,-141,-157,85,186]', 2043),
  ('mse-5116554-danielv-2045', '[-161,-119,-64,-59,168]', 2045),
  ('mse-5116554-danielv-2046', '[-1,0,-1,4,4]', 2046),
  ('mse-5116554-danielv-2047', '[-1,0,0,4,4]', 2047),
  ('mse-5116554-danielv-2049', '[-188,4,1,4,188]', 2049),
  ('mse-5116554-danielv-2050', '[1,4,0,1,4]', 2050),
  ('mse-5116554-danielv-2051', '[4,4,1,1,1]', 2051),
  ('mse-5116554-danielv-2053', '[6,13,-14,-3,11]', 2053),
  ('mse-5116554-danielv-2054', '[83,103,-91,-89,-82]', 2054),
  ('mse-5116554-danielv-2056', '[-118,310,-355,210,299]', 2056),
  ('mse-5116554-danielv-2058', '[-358,66,-226,-99,365]', 2058),
  ('mse-5116554-danielv-2060', '[13,16,-17,4,4]', 2060),
  ('mse-5116554-danielv-2063', '[-166,-130,-78,72,175]', 2063),
  ('mse-5116554-danielv-2066', '[-82,99,-90,-1,40]', 2066),
  ('mse-5116554-danielv-2067', '[-82,99,-90,0,40]', 2067),
  ('mse-5116554-danielv-2068', '[-20,14,-17,0,21]', 2068),
  ('mse-5116554-danielv-2069', '[-20,14,-17,1,21]', 2069),
  ('mse-5116554-danielv-2070', '[-4,1,-2,0,5]', 2070),
  ('mse-5116554-danielv-2071', '[-2,1,-4,1,5]', 2071),
  ('mse-5116554-danielv-2072', '[-183,64,-241,-132,254]', 2072),
  ('mse-5116554-danielv-2078', '[-1,-1,2,4,4]', 2078),
  ('mse-5116554-danielv-2079', '[2,4,-1,0,4]', 2079),
  ('mse-5116554-danielv-2081', '[0,2,1,4,4]', 2081),
  ('mse-5116554-danielv-2082', '[1,2,1,4,4]', 2082),
  ('mse-5116554-danielv-2083', '[-382,144,-156,243,374]', 2083),
  ('mse-5116554-danielv-2087', '[244,284,-313,-258,270]', 2087),
  ('mse-5116554-danielv-2088', '[15,21,-22,-9,13]', 2088),
  ('mse-5116554-danielv-2089', '[82,142,-137,-105,-53]', 2089),
  ('mse-5116554-danielv-2095', '[60,111,-112,-24,20]', 2095),
  ('mse-5116554-danielv-2098', '[-291,340,-266,-235,-210]', 2098),
  ('mse-5116554-danielv-2099', '[2,99,-90,-82,40]', 2099)
)
INSERT INTO submissions
  (id, category_id, contributor_id, left_terms, right_terms, tool_text, discovered_at)
SELECT incoming.id, '5-5-n', contributors.id, incoming.left_terms,
       json_array(incoming.target), NULL, '2025-12-24T22:03:00Z'
FROM incoming
JOIN contributors ON contributors.name = 'DanielV';

-- Link every imported row, plus the eight normalized identities that were
-- already present, to the MSE source page.
INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT submissions.id, resources.id, 'source'
FROM submissions
JOIN resources
  ON resources.url = 'https://math.stackexchange.com/questions/5115991/can-2025-and-2026-be-written-as-sums-of-five-fifth-powers'
WHERE submissions.id LIKE 'mse-5116275-%'
   OR submissions.id LIKE 'mse-5116554-%'
   OR submissions.id LIKE 'mse-5139375-%'
   OR submissions.id IN (
     'simon-goater-5-5-n-6',
     'simon-goater-5-5-n-8',
     'simon-goater-5-5-n-10',
     'mse-5139124-e2302f4c1916274b5600',
     'mse-5139124-55b01b9ca9afeed77667',
     'chat-164134-aleksandr-2025',
     'chat-164134-mezzoctane-2026',
     'chat-164134-mezzoctane-2027'
   );

-- Preserve the tools linked by the source answers.
INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT submissions.id, resources.id, 'tool'
FROM submissions
JOIN resources
  ON resources.url = 'https://play.rust-lang.org/?edition=2024&gist=677b4d936bbea05a41b812c22a881a64&mode=release&version=stable'
WHERE (
  submissions.id LIKE 'mse-5116554-danielv-%'
  OR submissions.id IN (
     'simon-goater-5-5-n-6',
     'simon-goater-5-5-n-8',
     'simon-goater-5-5-n-10',
     'mse-5139124-e2302f4c1916274b5600',
     'mse-5139124-55b01b9ca9afeed77667'
  )
)
AND submissions.id <> 'mse-5116554-danielv-4976';

INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT submissions.id, resources.id, 'tool'
FROM submissions
JOIN resources
  ON resources.url = 'https://play.rust-lang.org/?edition=2024&gist=97684d4abab5935a2a920144f9233af2&mode=release&version=stable'
WHERE submissions.id = 'mse-5116554-danielv-4976';

INSERT OR IGNORE INTO submission_resources (submission_id, resource_id, role)
SELECT submissions.id, resources.id, 'tool'
FROM submissions
JOIN resources
  ON resources.url = 'https://www.wolframcloud.com/obj/bb76659c-e970-4ade-bc3e-733c7214002e'
WHERE submissions.id IN ('mse-5116275-ydd-2025', 'mse-5116275-ydd-2026');
