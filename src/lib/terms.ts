// Terms are stored as JSON arrays in submissions.left_terms/right_terms. A term
// that fits a JavaScript number exactly (|x| ≤ 2^53 − 1) is a JSON number, as
// it always has been; a larger one is a JSON string of its decimal digits,
// because JSON parsers, D1 included, read big numbers as lossy floats. Each
// term therefore has exactly one stored form, which keeps
// UNIQUE(category_id, left_terms, right_terms) meaningful.
export const MAX_TERM_DIGITS = 100;

const MAX_SAFE = BigInt(Number.MAX_SAFE_INTEGER);
const CANONICAL_DECIMAL = /^-?[1-9]\d*$/;

function absolute(value: bigint) {
	return value < 0n ? -value : value;
}

export function parseStoredTerms(value: string): bigint[] {
	const parsed: unknown = JSON.parse(value);
	if (!Array.isArray(parsed)) throw new Error(`Terms ${value} are not a JSON array.`);
	return parsed.map((term: unknown) => {
		if (typeof term === 'number') {
			if (!Number.isSafeInteger(term)) throw new Error(`Term ${term} is not a safe integer.`);
			return BigInt(term);
		}
		if (typeof term === 'string' && CANONICAL_DECIMAL.test(term)) {
			const number = BigInt(term);
			if (absolute(number) > MAX_SAFE) return number;
		}
		throw new Error(`Term ${JSON.stringify(term)} is not in canonical stored form.`);
	});
}

export function serializeTerms(values: bigint[]) {
	return `[${values.map((value) => (absolute(value) > MAX_SAFE ? `"${value}"` : `${value}`)).join(',')}]`;
}
