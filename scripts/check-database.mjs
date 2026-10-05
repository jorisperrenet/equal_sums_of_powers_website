import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { ELLIPTIC_FAMILY_CATEGORY, ellipticFamilyK } from '../src/lib/elliptic-family.ts';
import { parseStoredTerms } from '../src/lib/terms.ts';

const wrangler = fileURLToPath(
	new URL('../node_modules/wrangler/bin/wrangler.js', import.meta.url)
);
const remote = process.argv.includes('--remote');
const persistIndex = process.argv.indexOf('--persist-to');
const persistTo = persistIndex >= 0 ? process.argv[persistIndex + 1] : null;

function execute(query) {
	const execution = spawnSync(
		process.execPath,
		[
			wrangler,
			'd1',
			'execute',
			'manifold',
			remote ? '--remote' : '--local',
			'--command',
			query,
			'--json',
			...(persistTo ? ['--persist-to', persistTo] : [])
		],
		// Production returns several megabytes; the 1 MB default maxBuffer would truncate the JSON.
		{ encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 }
	);
	if (execution.error || execution.status !== 0) {
		if (execution.error) process.stderr.write(`${execution.error.message}\n`);
		process.stderr.write(execution.stderr || execution.stdout);
		process.exit(execution.status ?? 1);
	}
	return JSON.parse(execution.stdout).flatMap((batch) => batch.results ?? []);
}

const rows = execute(`SELECT s.id, s.left_terms, s.right_terms, s.max_term, s.discovered_at,
 c.id AS category_id, c.exponent, c.left_count, c.right_count, c.format,
 contributor.id AS contributor_id
 FROM submissions s
 LEFT JOIN categories c ON c.id = s.category_id
 LEFT JOIN contributors contributor ON contributor.id = s.contributor_id
 ORDER BY s.id`);
const categories = execute(`SELECT id, format, submission_count FROM categories ORDER BY id`);
const coverage = execute(
	`SELECT category_id, n, solution_count FROM target_coverage ORDER BY category_id, n`
);
const claimCount = execute(`SELECT COUNT(*) AS count FROM search_claims`)[0]?.count ?? 0;
// Derived data from migration 0025, checked only once that migration is applied.
const hasMigration0025 =
	execute(
		`SELECT COUNT(*) AS count FROM sqlite_master WHERE type = 'table' AND name = 'resource_submission_counts'`
	)[0]?.count > 0;
// The family_k column from migration 0030.
const hasMigration0030 =
	execute(
		`SELECT COUNT(*) AS count FROM pragma_table_info('submissions') WHERE name = 'family_k'`
	)[0]?.count > 0;
const familyKs = hasMigration0030
	? new Map(execute(`SELECT id, family_k FROM submissions`).map((row) => [row.id, row.family_k]))
	: new Map();
const identityKeys = hasMigration0025
	? new Map(
			execute(`SELECT id, identity_key FROM submissions`).map((row) => [row.id, row.identity_key])
		)
	: new Map();
const resourceCounts = hasMigration0025
	? execute(`SELECT r.id, sc.submission_count,
		 (SELECT COUNT(DISTINCT submission_id) FROM submission_resources sr WHERE sr.resource_id = r.id) AS expected
		 FROM resources r LEFT JOIN resource_submission_counts sc ON sc.resource_id = r.id`)
	: [];

const failures = [];
const identities = new Map();
const submissionCounts = new Map();
const coverageCounts = new Map();

function fail(row, message) {
	failures.push(`${row.id}: ${message}`);
}

// Safe integers as JSON numbers, larger ones as JSON strings of their digits.
function parseTerms(row, column) {
	try {
		return parseStoredTerms(row[column]);
	} catch (error) {
		fail(row, `${column}: ${error.message}`);
		return [];
	}
}

// The sort key stored in max_term (migration 0030): the integer itself while
// it fits a JavaScript number, otherwise 'LLL:digits'.
function maxTermKey(value) {
	if (value <= BigInt(Number.MAX_SAFE_INTEGER)) return Number(value);
	const digits = value.toString();
	return `${String(digits.length).padStart(3, '0')}:${digits}`;
}

function absolute(value) {
	return value < 0n ? -value : value;
}

function gcd(left, right) {
	left = absolute(left);
	right = absolute(right);
	while (right) [left, right] = [right, left % right];
	return left;
}

function descending(left, right) {
	return left > right ? -1 : left < right ? 1 : 0;
}

function compare(left, right) {
	for (let index = 0; index < Math.min(left.length, right.length); index += 1) {
		if (left[index] !== right[index]) return left[index] > right[index] ? 1 : -1;
	}
	return left.length - right.length;
}

function hasNonzeroCrossSideCancellation(left, right) {
	const leftCounts = new Map();
	for (const value of left) {
		if (value !== 0n) leftCounts.set(value, (leftCounts.get(value) ?? 0) + 1);
	}
	for (const value of right) {
		const count = leftCounts.get(value) ?? 0;
		if (value !== 0n && count > 0) return true;
	}
	return false;
}

function normalizedKey(row, left, right) {
	if (row.format === 'target') {
		left.sort((a, b) => {
			const absoluteA = absolute(a);
			const absoluteB = absolute(b);
			return absoluteA === absoluteB ? descending(a, b) : descending(absoluteA, absoluteB);
		});
		if (right[0] === 0n && left[0] < 0n) left = left.map((value) => -value);
		return `${left.join(',')}=${right.join(',')}`;
	}
	left.sort(descending);
	if (row.format === 'near_miss') {
		const residual = right.pop();
		right.sort(descending);
		return `${left.join(',')}=${right.join(',')};${residual}`;
	}
	right.sort(descending);
	if (left.length === right.length && compare(left, right) < 0) [left, right] = [right, left];
	return `${left.join(',')}=${right.join(',')}`;
}

for (const row of rows) {
	if (!row.category_id) {
		fail(row, 'references a missing category');
		continue;
	}
	submissionCounts.set(row.category_id, (submissionCounts.get(row.category_id) ?? 0) + 1);
	if (!row.contributor_id) fail(row, 'references a missing contributor');
	if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(row.discovered_at)) {
		fail(row, `discovered_at "${row.discovered_at}" is not in YYYY-MM-DDTHH:MM:SSZ form`);
	}
	const left = parseTerms(row, 'left_terms');
	const right = parseTerms(row, 'right_terms');
	if (!left.length || !right.length) continue;

	// The trigger-maintained sort key must equal the largest absolute term on
	// either side (including a target N or a near-miss residual).
	const expectedMaxTerm = [...left, ...right].reduce(
		(largest, value) => (absolute(value) > largest ? absolute(value) : largest),
		0n
	);
	if (row.max_term !== maxTermKey(expectedMaxTerm)) {
		fail(row, `max_term is ${row.max_term} but should be ${maxTermKey(expectedMaxTerm)}`);
	}
	if (hasMigration0030) {
		const expectedFamilyK =
			row.category_id === ELLIPTIC_FAMILY_CATEGORY ? ellipticFamilyK(left[0], right) : null;
		if (familyKs.get(row.id) !== expectedFamilyK) {
			fail(row, `family_k is ${familyKs.get(row.id)} but should be ${expectedFamilyK}`);
		}
	}

	let bases;
	let leftSum;
	let rightSum;
	let requiresPrimitive = true;
	const exponent = BigInt(row.exponent);
	if (row.format === 'target') {
		const coverageKey = `${row.category_id}:${right[0]}`;
		coverageCounts.set(coverageKey, (coverageCounts.get(coverageKey) ?? 0) + 1);
		if (left.length !== row.left_count || right.length !== 1) {
			fail(row, `expected ${row.left_count} signed terms and one target`);
		}
		if (right[0] < 0n || right[0] > 2500n) fail(row, 'target N is outside [0, 2500]');
		const terms = new Set(left);
		if (left.some((value) => value !== 0n && terms.has(-value))) {
			fail(row, 'signed target contains terms x and -x that cancel each other');
		}
		if (
			right[0] === 0n &&
			left.reduce((largest, value) => (absolute(value) > absolute(largest) ? value : largest), 0n) <
				0n
		) {
			fail(row, 'zero target has a negative greatest-absolute-value term');
		}
		bases = left;
		leftSum = left.reduce((sum, value) => sum + value ** exponent, 0n);
		rightSum = right[0];
		requiresPrimitive = right[0] === 0n;
	} else if (row.format === 'near_miss') {
		if (left.length !== row.left_count || right.length !== row.right_count + 1) {
			fail(row, `expected ${row.left_count} terms, ${row.right_count} terms, and a residual`);
		}
		const residual = right.at(-1);
		if (residual !== 1n && residual !== -1n) fail(row, 'near-miss residual is not +1 or -1');
		const rightBases = right.slice(0, -1);
		bases = [...left, ...rightBases];
		if (bases.some((value) => value <= 0n)) fail(row, 'near-miss bases must be positive');
		if (hasNonzeroCrossSideCancellation(left, rightBases)) {
			fail(row, 'near miss contains a nonzero base on both sides');
		}
		leftSum = left.reduce((sum, value) => sum + value ** exponent, 0n);
		rightSum = rightBases.reduce((sum, value) => sum + value ** exponent, residual ?? 0n);
	} else if (row.format === 'equality') {
		if (left.length !== row.left_count || right.length !== row.right_count) {
			fail(row, `expected ${row.left_count} left and ${row.right_count} right terms`);
		}
		bases = [...left, ...right];
		if (bases.some((value) => value <= 0n)) fail(row, 'equal-sum bases must be positive');
		if (hasNonzeroCrossSideCancellation(left, right)) {
			fail(row, 'equal sum contains a nonzero base on both sides');
		}
		leftSum = left.reduce((sum, value) => sum + value ** exponent, 0n);
		rightSum = right.reduce((sum, value) => sum + value ** exponent, 0n);
	} else {
		fail(row, `has unknown category format ${row.format}`);
		continue;
	}

	if (leftSum !== rightSum) fail(row, `power sums differ by ${absolute(leftSum - rightSum)}`);
	if (requiresPrimitive && bases.reduce(gcd, 0n) !== 1n) {
		fail(row, 'identity is not primitive');
	}
	const normalized = normalizedKey(row, [...left], [...right]);
	// identity_key uses a comma, not a semicolon, before the near-miss residual.
	const expectedIdentityKey = normalized.replace(';', ',');
	if (hasMigration0025 && identityKeys.get(row.id) !== expectedIdentityKey) {
		fail(row, `identity_key is ${identityKeys.get(row.id)} but should be ${expectedIdentityKey}`);
	}
	const key = `${row.category_id}:${normalized}`;
	if (identities.has(key)) fail(row, `duplicates ${identities.get(key)}`);
	else identities.set(key, row.id);
}

// Derived data maintained by the triggers from migration 0023 must match a
// fresh tally of the submissions.
for (const category of categories) {
	const expected = submissionCounts.get(category.id) ?? 0;
	if (Number(category.submission_count) !== expected) {
		failures.push(
			`categories.${category.id}: submission_count is ${category.submission_count} but ${expected} submissions exist`
		);
	}
}
const coverageRows = new Map(
	coverage.map((entry) => [`${entry.category_id}:${entry.n}`, Number(entry.solution_count)])
);
for (const [key, expected] of coverageCounts) {
	if (coverageRows.get(key) !== expected) {
		failures.push(
			`target_coverage ${key}: has ${coverageRows.get(key) ?? 'no row'} but ${expected} solutions exist`
		);
	}
}
for (const [key, count] of coverageRows) {
	if (!coverageCounts.has(key)) {
		failures.push(`target_coverage ${key}: has ${count} but no submissions exist`);
	}
}

for (const resource of resourceCounts) {
	if (
		resource.submission_count === null ||
		Number(resource.submission_count) !== resource.expected
	) {
		failures.push(
			`resource_submission_counts.${resource.id}: is ${resource.submission_count ?? 'missing'} but ${resource.expected} submissions cite it`
		);
	}
}

if (Number(claimCount) > 20) {
	failures.push(`search_claims: contains ${claimCount} rows; maximum is 20`);
}

if (failures.length) {
	console.error(`Database audit failed with ${failures.length} problem(s):`);
	for (const failure of failures) console.error(`- ${failure}`);
	process.exit(1);
}

console.log(
	`Database audit passed: ${rows.length} submissions, ${categories.length} category counts, ${coverage.length} target coverage rows${hasMigration0025 ? `, identity keys and ${resourceCounts.length} resource counts` : ''}${hasMigration0030 ? ', family k' : ''} checked (${remote ? 'remote' : 'local'} D1).`
);
