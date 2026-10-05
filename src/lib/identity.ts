import { parseStoredTerms } from '$lib/terms';

export type IdentityShape = {
	exponent: number;
	left_count: number;
	right_count: number;
	format?: 'equality' | 'near_miss' | 'target';
};

function absolute(value: bigint) {
	return value < 0n ? -value : value;
}

function descending(left: bigint, right: bigint) {
	return left > right ? -1 : left < right ? 1 : 0;
}

function compareTerms(left: bigint[], right: bigint[]) {
	for (let index = 0; index < Math.min(left.length, right.length); index += 1) {
		if (left[index] !== right[index]) return left[index] > right[index] ? 1 : -1;
	}
	return left.length - right.length;
}

export function normalizeIdentity(leftJson: string, rightJson: string, shape: IdentityShape) {
	let left = parseStoredTerms(leftJson);
	let right = parseStoredTerms(rightJson);

	if (shape.format === 'target') {
		left.sort((a, b) => {
			const absoluteA = absolute(a);
			const absoluteB = absolute(b);
			return absoluteA === absoluteB ? descending(a, b) : descending(absoluteA, absoluteB);
		});
		if (right[0] === 0n && left[0] < 0n) left = left.map((term) => -term);
		return { left: left.map(String), right: right.map(String), residual: null };
	}

	left.sort(descending);
	if (shape.format === 'near_miss') {
		const residual = right.pop() ?? 1n;
		right.sort(descending);
		return { left: left.map(String), right: right.map(String), residual: residual.toString() };
	}

	right.sort(descending);
	if (shape.left_count === shape.right_count && compareTerms(left, right) < 0) {
		[left, right] = [right, left];
	}
	return { left: left.map(String), right: right.map(String), residual: null };
}

function powerSum(terms: string[], exponent: number, signed = false) {
	return terms
		.map((term, index) => {
			const negative = term.startsWith('-');
			const absolute = negative ? term.slice(1) : term;
			if (!signed) return `${absolute}^${exponent}`;
			if (index === 0) return `${negative ? '-' : ''}${absolute}^${exponent}`;
			return `${negative ? '- ' : '+ '}${absolute}^${exponent}`;
		})
		.join(signed ? ' ' : ' + ');
}

export function formatIdentity(leftJson: string, rightJson: string, shape: IdentityShape) {
	const identity = normalizeIdentity(leftJson, rightJson, shape);
	if (shape.format === 'target') {
		return `${powerSum(identity.left, shape.exponent, true)} = ${identity.right[0]}`;
	}
	const left = powerSum(identity.left, shape.exponent);
	const right = powerSum(identity.right, shape.exponent);
	if (shape.format === 'near_miss') {
		return `${left} = ${right} ${identity.residual!.startsWith('-') ? '-' : '+'} 1`;
	}
	return `${left} = ${right}`;
}

// The canonical key stored in submissions.identity_key. The view
// submission_identity_keys (migrations 0025 and 0030) derives the same string
// in SQL, so the two must change together.
export function identityKey(leftJson: string, rightJson: string, shape: IdentityShape) {
	const identity = normalizeIdentity(leftJson, rightJson, shape);
	const right =
		shape.format === 'near_miss' ? [...identity.right, identity.residual!] : identity.right;
	return `${identity.left.join(',')}=${right.join(',')}`;
}
