import { mkdtempSync, readFileSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const defaultSource = 'http://euler.free.fr/database.txt';
const source = process.argv[2] ?? defaultSource;

function sqlite(database, sql) {
	const execution = spawnSync('sqlite3', ['-batch', database], {
		input: sql,
		encoding: 'utf8'
	});
	if (execution.status !== 0) {
		throw new Error(execution.stderr || `sqlite3 exited with status ${execution.status}`);
	}
	return execution.stdout;
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

function normalizedKey(left, right) {
	left.sort(descending);
	right.sort(descending);
	if (left.length === right.length && compare(left, right) < 0) [left, right] = [right, left];
	return `${left.join(',')}=${right.join(',')}`;
}

function parseTerms(expression) {
	const terms = [];
	for (const token of expression.replaceAll(' ', '').split('+')) {
		const match = token.match(/^(\d+)(?:\*(\d+))?$/);
		if (!match) throw new Error(`cannot parse term "${token}"`);
		const value = BigInt(match[1]);
		const copies = Number(match[2] ?? 1);
		for (let index = 0; index < copies; index += 1) terms.push(value);
	}
	return terms;
}

function parseReference(text, categories) {
	const entries = [];
	const rejected = [];
	for (const [index, line] of text.split(/\r?\n/).entries()) {
		const match = line.match(
			/^\s*\((\d+),\s*(\d+),\s*(\d+)\)\s+([0-9+*\s]+?)\s*=\s*([0-9+*\s]+?)(?=\s*(?:\(|$))/
		);
		if (!match) continue;
		const tuple = `${match[1]}-${match[2]}-${match[3]}`;
		const category = categories.get(tuple);
		if (!category) continue;
		try {
			const left = parseTerms(match[4]);
			const right = parseTerms(match[5]);
			if (left.length !== category.leftCount || right.length !== category.rightCount) {
				throw new Error(`expanded term counts are ${left.length} and ${right.length}`);
			}
			const exponent = BigInt(category.exponent);
			const leftSum = left.reduce((sum, value) => sum + value ** exponent, 0n);
			const rightSum = right.reduce((sum, value) => sum + value ** exponent, 0n);
			if (leftSum !== rightSum) throw new Error('power sums are unequal');
			entries.push({
				categoryId: category.id,
				key: normalizedKey(left, right),
				line: line.trim()
			});
		} catch (error) {
			rejected.push(`line ${index + 1}: ${error.message}: ${line.trim()}`);
		}
	}
	return { entries, rejected };
}

async function readSource(location) {
	if (/^https?:\/\//.test(location)) {
		const response = await fetch(location);
		if (!response.ok) throw new Error(`download failed: HTTP ${response.status}`);
		return response.text();
	}
	return readFileSync(resolve(location), 'utf8');
}

const temporaryDirectory = mkdtempSync(join(tmpdir(), 'manifold-euler-'));
const database = join(temporaryDirectory, 'manifold.sqlite');

try {
	for (const filename of readdirSync(join(root, 'migrations'))
		.filter((name) => name.endsWith('.sql'))
		.sort()) {
		sqlite(database, readFileSync(join(root, 'migrations', filename), 'utf8'));
	}

	const categories = new Map();
	const categoryRows = sqlite(
		database,
		`SELECT id, exponent, left_count, right_count
		 FROM categories WHERE format = 'equality'
		 ORDER BY exponent, left_count, right_count;`
	);
	for (const row of categoryRows.trim().split('\n')) {
		if (!row) continue;
		const [id, exponent, leftCount, rightCount] = row.split('|');
		categories.set(`${exponent}-${leftCount}-${rightCount}`, {
			id,
			exponent: Number(exponent),
			leftCount: Number(leftCount),
			rightCount: Number(rightCount)
		});
	}

	const existing = new Set();
	const submissionRows = sqlite(
		database,
		`SELECT category_id, left_terms, right_terms
		 FROM submissions
		 WHERE category_id IN (SELECT id FROM categories WHERE format = 'equality');`
	);
	for (const row of submissionRows.trim().split('\n')) {
		if (!row) continue;
		const [categoryId, leftJson, rightJson] = row.split('|');
		existing.add(
			`${categoryId}:${normalizedKey(
				JSON.parse(leftJson).map(BigInt),
				JSON.parse(rightJson).map(BigInt)
			)}`
		);
	}

	const referenceText = await readSource(source);
	const { entries, rejected } = parseReference(referenceText, categories);
	const seenReference = new Set();
	const missing = entries.filter((entry) => {
		const qualifiedKey = `${entry.categoryId}:${entry.key}`;
		if (seenReference.has(qualifiedKey)) return false;
		seenReference.add(qualifiedKey);
		return !existing.has(qualifiedKey);
	});

	const grouped = Map.groupBy(missing, (entry) => entry.categoryId);
	console.log(
		`Compared ${seenReference.size} reference identities in ${categories.size} current equality categories.`
	);
	console.log(`Missing from the public database: ${missing.length}`);
	for (const category of categories.values()) {
		const categoryMissing = grouped.get(category.id) ?? [];
		if (!categoryMissing.length) continue;
		console.log(`\n${category.id} (${categoryMissing.length})`);
		for (const entry of categoryMissing) console.log(`- ${entry.line}`);
	}
	if (rejected.length) {
		console.error(`\nRejected ${rejected.length} matching reference line(s):`);
		for (const message of rejected) console.error(`- ${message}`);
		process.exitCode = 2;
	}
} finally {
	rmSync(temporaryDirectory, { recursive: true, force: true });
}
