import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const wrangler = fileURLToPath(
	new URL('../node_modules/wrangler/bin/wrangler.js', import.meta.url)
);
const remote = process.argv.includes('--remote');
const persistIndex = process.argv.indexOf('--persist-to');
const persistTo = persistIndex >= 0 ? process.argv[persistIndex + 1] : null;
const query = `SELECT s.id, s.left_terms, s.right_terms,
 c.id AS category_id, c.exponent, c.left_count, c.right_count, c.format,
 contributor.id AS contributor_id
 FROM submissions s
 LEFT JOIN categories c ON c.id = s.category_id
 LEFT JOIN contributors contributor ON contributor.id = s.contributor_id
 ORDER BY s.id`;
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
	{ encoding: 'utf8' }
);
if (execution.status !== 0) {
	process.stderr.write(execution.stderr || execution.stdout);
	process.exit(execution.status ?? 1);
}

const rows = JSON.parse(execution.stdout).flatMap((batch) => batch.results ?? []);
const failures = [];
const identities = new Map();

function fail(row, message) {
	failures.push(`${row.id}: ${message}`);
}

function parseTerms(row, column) {
	let values;
	try {
		values = JSON.parse(row[column]);
	} catch {
		fail(row, `${column} is not valid JSON`);
		return [];
	}
	if (!Array.isArray(values) || values.some((value) => !Number.isSafeInteger(value))) {
		fail(row, `${column} must be an array of JSON integers, not strings`);
		return [];
	}
	return values.map(BigInt);
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
	if (!row.contributor_id) fail(row, 'references a missing contributor');
	const left = parseTerms(row, 'left_terms');
	const right = parseTerms(row, 'right_terms');
	if (!left.length || !right.length) continue;

	let bases;
	let leftSum;
	let rightSum;
	let requiresPrimitive = true;
	const exponent = BigInt(row.exponent);
	if (row.format === 'target') {
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
		if (bases.some((value) => value < 0n)) fail(row, 'equal-sum bases must be non-negative');
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
	const key = `${row.category_id}:${normalizedKey(row, [...left], [...right])}`;
	if (identities.has(key)) fail(row, `duplicates ${identities.get(key)}`);
	else identities.set(key, row.id);
}

const claimCountQuery = `SELECT COUNT(*) AS count FROM search_claims`;
const claimCountExecution = spawnSync(
	process.execPath,
	[
		wrangler,
		'd1',
		'execute',
		'manifold',
		remote ? '--remote' : '--local',
		'--command',
		claimCountQuery,
		'--json',
		...(persistTo ? ['--persist-to', persistTo] : [])
	],
	{ encoding: 'utf8' }
);
if (claimCountExecution.status !== 0) {
	process.stderr.write(claimCountExecution.stderr || claimCountExecution.stdout);
	process.exit(claimCountExecution.status ?? 1);
}
const claimCount =
	JSON.parse(claimCountExecution.stdout).flatMap((batch) => batch.results ?? [])[0]?.count ?? 0;
if (Number(claimCount) > 20) {
	failures.push(`search_claims: contains ${claimCount} rows; maximum is 20`);
}

if (failures.length) {
	console.error(`Database audit failed with ${failures.length} problem(s):`);
	for (const failure of failures) console.error(`- ${failure}`);
	process.exit(1);
}

console.log(
	`Database audit passed: ${rows.length} submissions checked (${remote ? 'remote' : 'local'} D1).`
);
