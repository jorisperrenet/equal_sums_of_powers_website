import { TARGET_MAX, TARGET_MIN } from '$lib/target-range';

export type CategoryShape = {
	id: string;
	exponent: number;
	left_count: number;
	right_count: number;
	format?: 'equality' | 'target' | 'near_miss';
};

export type ParsedEquation = {
	left: number[];
	right: number[];
	equation: string;
	powerSum: string;
	maxTerm: number;
};

const MAX_INPUT_LENGTH = 500;
// Kept below 2^53 so every term is an exact JavaScript number; only the power
// sums need BigInt.
const MAX_TERM = 1e15;
const SUPERSCRIPTS = '⁰¹²³⁴⁵⁶⁷⁸⁹';

function parseSide(value: string, exponent: number): number[] {
	if (!value) throw new Error('Both sides of the equation are required.');

	return value.split('+').map((raw) => {
		const token = raw.trim().replaceAll(',', '');
		const match = token.match(/^(\d+)(?:\^(\d+))?$/);
		if (!match) throw new Error(`“${raw.trim()}” is not a non-negative integer.`);
		if (match[2] && Number(match[2]) !== exponent) {
			throw new Error(`Every written exponent must be ${exponent}.`);
		}
		const number = Number(match[1]);
		if (number > MAX_TERM) throw new Error('Each term must be at most 1,000,000,000,000,000.');
		return number;
	});
}

function descending(left: number, right: number) {
	return left > right ? -1 : left < right ? 1 : 0;
}

function compareTerms(left: number[], right: number[]) {
	for (let index = 0; index < Math.min(left.length, right.length); index += 1) {
		if (left[index] !== right[index]) return left[index] > right[index] ? 1 : -1;
	}
	return left.length - right.length;
}

function sorted(values: number[]) {
	return [...values].sort(descending);
}

function sortedSigned(values: number[]) {
	return [...values].sort((left, right) => {
		const absoluteLeft = Math.abs(left);
		const absoluteRight = Math.abs(right);
		return absoluteLeft === absoluteRight
			? descending(left, right)
			: descending(absoluteLeft, absoluteRight);
	});
}

function parseSignedSide(value: string, exponent: number): number[] {
	const normalized = value
		.trim()
		.replaceAll(' ', '')
		.replace(/(?!^)-/g, '+-');
	if (!normalized) throw new Error('Enter the signed power sum.');

	return normalized.split('+').map((token) => {
		const match = token.match(/^([+-]?\d+)(?:\^(\d+))?$/);
		if (!match) throw new Error(`“${token}” is not a valid signed integer term.`);
		if (match[2] && Number(match[2]) !== exponent) {
			throw new Error(`Every written exponent must be ${exponent}.`);
		}
		const number = Number(match[1]);
		if (Math.abs(number) > MAX_TERM) {
			throw new Error('The absolute value of each term must be at most 1,000,000,000,000,000.');
		}
		return number;
	});
}

function absolute(value: bigint) {
	return value < 0n ? -value : value;
}

function powerSum(values: number[], exponent: number) {
	return values.reduce((total, value) => total + BigInt(value) ** BigInt(exponent), 0n);
}

function greatestCommonDivisor(a: number, b: number) {
	let left = Math.abs(a);
	let right = Math.abs(b);
	while (right !== 0) {
		[left, right] = [right, left % right];
	}
	return left;
}

function requirePrimitive(values: number[]) {
	const divisor = values.reduce(greatestCommonDivisor, 0);
	if (divisor !== 1) {
		throw new Error('The solution is not primitive: all bases have a common factor.');
	}
}

function requireNoCancellation(values: number[]) {
	const terms = new Set(values);
	if (values.some((value) => value !== 0 && terms.has(-value))) {
		throw new Error('The solution contains terms x and -x that cancel each other.');
	}
}

function requireNoCrossSideCancellation(left: number[], right: number[]) {
	const leftCounts = new Map<number, number>();
	for (const value of left) {
		if (value !== 0) leftCounts.set(value, (leftCounts.get(value) ?? 0) + 1);
	}

	let cancellationCount = 0;
	for (const value of right) {
		const count = leftCounts.get(value) ?? 0;
		if (value !== 0 && count > 0) {
			cancellationCount += 1;
			leftCounts.set(value, count - 1);
		}
	}
	if (cancellationCount > 0) {
		throw new Error(
			`The solution contains ${cancellationCount} nonzero ${cancellationCount === 1 ? 'term' : 'terms'} that cancel across both sides.`
		);
	}
}

function formatSignedTerms(values: number[]) {
	return values
		.map((value, index) => {
			if (index === 0) return value.toString();
			return value < 0 ? `- ${-value}` : `+ ${value}`;
		})
		.join(' ');
}

export function parseAndVerify(rawInput: string, category: CategoryShape): ParsedEquation {
	if (!rawInput.trim()) throw new Error('Enter an equation to verify.');
	if (rawInput.length > MAX_INPUT_LENGTH) throw new Error('The equation is too long.');

	const normalized = rawInput
		.trim()
		.replaceAll('−', '-')
		.replace(
			/[⁰¹²³⁴⁵⁶⁷⁸⁹]+/g,
			(digits) => `^${[...digits].map((digit) => SUPERSCRIPTS.indexOf(digit)).join('')}`
		);
	const prefix = normalized.match(/^\s*\(([^)]+)\)\s*/);
	if (prefix) {
		const supplied = prefix[1].replaceAll(' ', '').toUpperCase();
		const expected =
			category.format === 'target'
				? `${category.exponent},${category.left_count};N`
				: category.format === 'near_miss'
					? `${category.exponent},${category.left_count},${category.right_count};±1`
					: `${category.exponent},${category.left_count},${category.right_count}`;
		if (supplied !== expected) {
			throw new Error('The category prefix does not match the selected category.');
		}
	}
	const input = prefix ? normalized.slice(prefix[0].length) : normalized;
	const parts = input.split('=');
	if (parts.length !== 2) throw new Error('Use exactly one equals sign.');
	if (category.format === 'target') {
		const leftIsTarget = /^[+-]?\d+$/.test(parts[0].trim());
		const rightIsTarget = /^[+-]?\d+$/.test(parts[1].trim());
		if (leftIsTarget === rightIsTarget) {
			throw new Error('Put one integer N on one side and the signed power sum on the other.');
		}
		const target = Number((leftIsTarget ? parts[0] : parts[1]).trim());
		if (target < TARGET_MIN || target > TARGET_MAX) {
			throw new Error(`N must be between ${TARGET_MIN} and ${TARGET_MAX}.`);
		}
		const signedTerms = parseSignedSide(leftIsTarget ? parts[1] : parts[0], category.exponent);
		if (signedTerms.length !== category.left_count) {
			throw new Error(`This category needs exactly ${category.left_count} signed terms.`);
		}
		// A nonzero fixed target prevents scaling one solution into infinitely many.
		// For N = 0, retain the primitive condition because scaling preserves the target.
		if (target === 0) requirePrimitive(signedTerms);
		requireNoCancellation(signedTerms);
		const calculated = powerSum(signedTerms, category.exponent);
		if (calculated !== BigInt(target)) {
			const difference = absolute(calculated - BigInt(target));
			throw new Error(`Not equal — the power sum differs from N by ${difference}.`);
		}
		const max = Math.max(...signedTerms.map(Math.abs));
		let normalizedTerms = sortedSigned(signedTerms);
		if (target === 0 && normalizedTerms[0] < 0) {
			normalizedTerms = normalizedTerms.map((term) => -term);
		}
		return {
			left: normalizedTerms,
			right: [target],
			equation: `${formatSignedTerms(normalizedTerms)} = ${target}`,
			powerSum: target.toString(),
			maxTerm: max
		};
	}
	if (category.format === 'near_miss') {
		const left = parseSide(parts[0], category.exponent);
		if (left.length !== category.left_count || left.some((term) => term === 0)) {
			throw new Error(
				`This category needs exactly ${category.left_count} positive terms on the left.`
			);
		}
		const rightMatch = parts[1]
			.trim()
			.replaceAll(' ', '')
			.match(/^(.*)([+-])1(?:\^(\d+))?$/);
		if (!rightMatch || !rightMatch[1]) {
			throw new Error(
				`Write the right side as ${category.right_count} positive ${category.exponent}th-power ${category.right_count === 1 ? 'base' : 'bases'} followed by +1 or -1.`
			);
		}
		if (rightMatch[3] && Number(rightMatch[3]) !== category.exponent) {
			throw new Error(`Every written exponent must be ${category.exponent}.`);
		}
		const right = parseSide(rightMatch[1], category.exponent);
		if (right.length !== category.right_count || right.some((term) => term === 0)) {
			throw new Error(
				`This category needs exactly ${category.right_count} positive ${category.right_count === 1 ? 'term' : 'terms'} before the residual.`
			);
		}
		requirePrimitive([...left, ...right]);
		const residual = rightMatch[2] === '+' ? 1 : -1;
		const leftSum = powerSum(left, category.exponent);
		const rightSum = powerSum(right, category.exponent) + BigInt(residual);
		if (leftSum !== rightSum) {
			const difference = absolute(leftSum - rightSum);
			throw new Error(`Not equal — the two sides differ by ${difference}.`);
		}
		requireNoCrossSideCancellation(left, right);
		const max = Math.max(...left, ...right);
		const normalizedLeft = sorted(left);
		const normalizedRight = sorted(right);
		return {
			left: normalizedLeft,
			right: [...normalizedRight, residual],
			equation: `${normalizedLeft.map(String).join(' + ')} = ${normalizedRight.map(String).join(' + ')} ${residual > 0 ? '+' : '-'} 1`,
			powerSum: leftSum.toString(),
			maxTerm: max
		};
	}

	const left = parseSide(parts[0], category.exponent);
	const right = parseSide(parts[1], category.exponent);
	if (left.length !== category.left_count || right.length !== category.right_count) {
		throw new Error(
			`This category needs ${category.left_count} terms on the left and ${category.right_count} on the right.`
		);
	}
	requirePrimitive([...left, ...right]);

	const leftSum = powerSum(left, category.exponent);
	const rightSum = powerSum(right, category.exponent);
	if (leftSum !== rightSum) {
		const difference = leftSum > rightSum ? leftSum - rightSum : rightSum - leftSum;
		throw new Error(`Not equal — the two power sums differ by ${difference.toString()}.`);
	}

	let normalizedLeft = sorted(left);
	let normalizedRight = sorted(right);
	if ([...left, ...right].every((term) => term === 0)) {
		throw new Error('The all-zero identity is trivial and cannot be published.');
	}
	if (
		category.left_count === category.right_count &&
		compareTerms(normalizedLeft, normalizedRight) === 0
	) {
		throw new Error('A rearrangement of the same terms is a trivial identity.');
	}
	requireNoCrossSideCancellation(left, right);
	if (
		category.left_count === category.right_count &&
		compareTerms(normalizedLeft, normalizedRight) < 0
	) {
		[normalizedLeft, normalizedRight] = [normalizedRight, normalizedLeft];
	}
	const max = Math.max(...left, ...right);

	return {
		left: normalizedLeft,
		right: normalizedRight,
		equation: `${normalizedLeft.map(String).join(' + ')} = ${normalizedRight.map(String).join(' + ')}`,
		powerSum: leftSum.toString(),
		maxTerm: max
	};
}
