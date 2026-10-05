// Jacobi and Madden (2008) showed that e⁴ = a⁴ + b⁴ + c⁴ + d⁴ has infinitely
// many solutions with e = a + b + c + d, and in 2026 this was generalized to
// e = a + k³(b + c + d) for rational k (https://mathoverflow.net/q/515455):
// for every such k, one solution lies on an elliptic curve that yields
// infinitely many more. Only these solutions are "interesting" among the
// tens of thousands in (4, 1, 4), so each row records its k, if any, in
// submissions.family_k.
export const ELLIPTIC_FAMILY_CATEGORY = '4-1-4';

function absolute(value: bigint) {
	return value < 0n ? -value : value;
}

function gcd(left: bigint, right: bigint) {
	left = absolute(left);
	right = absolute(right);
	while (right) [left, right] = [right, left % right];
	return left;
}

// The integer cube root of a non-negative value, or null when it is not a cube.
function exactCubeRoot(value: bigint) {
	if (value < 2n) return value;
	// Start above the root, from a power of two, and descend with Newton steps.
	let root = 1n << BigInt(Math.ceil(value.toString(2).length / 3));
	for (;;) {
		const next = (2n * root + value / (root * root)) / 3n;
		if (next >= root) break;
		root = next;
	}
	return root ** 3n === value ? root : null;
}

function rationalCubeRoot(numerator: bigint, denominator: bigint) {
	const divisor = gcd(numerator, denominator);
	const n = exactCubeRoot(numerator / divisor);
	const m = n === null ? null : exactCubeRoot(denominator / divisor);
	if (n === null || m === null) return null;
	return { n, m };
}

// Every k > 0 with e = a + k³(b + c + d) for some ordering and signs of the
// four terms, as "n" or "n/m" in lowest terms, sorted and joined with commas;
// null when there is none. The equation is unchanged by negating any term, so
// a solution is stored as absolute values and every sign pattern is tried.
// Negating b, c and d together maps k to −k, so k is taken positive.
export function ellipticFamilyK(e: bigint, terms: bigint[]): string | null {
	if (terms.length !== 4) return null;
	const found = new Map<string, number>();
	for (let index = 0; index < 4; index += 1) {
		const a = terms[index];
		const rest = terms.filter((_, other) => other !== index);
		for (const signA of [1n, -1n]) {
			const difference = e - signA * a;
			if (difference === 0n) continue;
			// Fixing the sign of b leaves the four patterns not related by a global flip.
			for (const [signC, signD] of [
				[1n, 1n],
				[1n, -1n],
				[-1n, 1n],
				[-1n, -1n]
			]) {
				const sum = rest[0] + signC * rest[1] + signD * rest[2];
				if (sum === 0n) continue;
				const root = rationalCubeRoot(absolute(difference), absolute(sum));
				if (!root) continue;
				const label = root.m === 1n ? `${root.n}` : `${root.n}/${root.m}`;
				found.set(label, Number(root.n) / Number(root.m));
			}
		}
	}
	if (!found.size) return null;
	return [...found.entries()]
		.sort((left, right) => left[1] - right[1])
		.map(([label]) => label)
		.join(',');
}
