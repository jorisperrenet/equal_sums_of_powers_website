import { TARGET_MAX, TARGET_MIN } from '$lib/target-range';

export type CategoryShape = {
	id: string;
	exponent: number;
	left_count: number;
	right_count: number;
	format?: 'equality' | 'target' | 'near_miss';
};

export type ParsedEquation = {
	left: bigint[];
	right: bigint[];
	equation: string;
	powerSum: string;
	maxTerm: number;
};

const MAX_INPUT_LENGTH = 500;
const MAX_BASE = 1_000_000_000n;

function parseSide(value: string, exponent: number): bigint[] {
	if (!value) throw new Error('Both sides of the equation are required.');

	return value.split('+').map((raw) => {
		const token = raw.trim().replaceAll(',', '');
		const match = token.match(/^(\d+)(?:\^(\d+))?$/);
		if (!match) throw new Error(`“${raw.trim()}” is not a non-negative integer.`);
		if (match[2] && Number(match[2]) !== exponent) {
			throw new Error(`Every written exponent must be ${exponent}.`);
		}
		const number = BigInt(match[1]);
		if (number > MAX_BASE) throw new Error('Each term must be at most 1,000,000,000.');
		return number;
	});
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

function sorted(values: bigint[]) {
	return [...values].sort(descending);
}

function sortedSigned(values: bigint[]) {
	return [...values].sort((left, right) => {
		const absoluteLeft = absolute(left);
		const absoluteRight = absolute(right);
		return absoluteLeft === absoluteRight
			? descending(left, right)
			: descending(absoluteLeft, absoluteRight);
	});
}

function parseSignedSide(value: string, exponent: number): bigint[] {
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
		const number = BigInt(match[1]);
		if (number > MAX_BASE || number < -MAX_BASE) {
			throw new Error('The absolute value of each term must be at most 1,000,000,000.');
		}
		return number;
	});
}

function absolute(value: bigint) {
	return value < 0n ? -value : value;
}

function greatestCommonDivisor(a: bigint, b: bigint) {
	let left = absolute(a);
	let right = absolute(b);
	while (right !== 0n) {
		[left, right] = [right, left % right];
	}
	return left;
}

function requirePrimitive(values: bigint[]) {
	const divisor = values.reduce(greatestCommonDivisor, 0n);
	if (divisor !== 1n) {
		throw new Error('The solution is not primitive: all bases have a common factor.');
	}
}

function formatSignedTerms(values: bigint[]) {
	return values
		.map((value, index) => {
			if (index === 0) return value.toString();
			return value < 0n ? `- ${absolute(value)}` : `+ ${value}`;
		})
		.join(' ');
}

export function parseAndVerify(rawInput: string, category: CategoryShape): ParsedEquation {
	if (!rawInput.trim()) throw new Error('Enter an equation to verify.');
	if (rawInput.length > MAX_INPUT_LENGTH) throw new Error('The equation is too long.');

	const normalized = rawInput
		.trim()
		.replaceAll('−', '-')
		.replaceAll('⁷', '^7')
		.replaceAll('⁵', '^5');
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
		const target = BigInt((leftIsTarget ? parts[0] : parts[1]).trim());
		if (target < BigInt(TARGET_MIN) || target > BigInt(TARGET_MAX)) {
			throw new Error(`N must be between ${TARGET_MIN} and ${TARGET_MAX}.`);
		}
		const signedTerms = parseSignedSide(leftIsTarget ? parts[1] : parts[0], category.exponent);
		if (signedTerms.length !== category.left_count) {
			throw new Error(`This category needs exactly ${category.left_count} signed terms.`);
		}
		requirePrimitive(signedTerms);
		const calculated = signedTerms.reduce(
			(total, value) => total + value ** BigInt(category.exponent),
			0n
		);
		if (calculated !== target) {
			const difference = absolute(calculated - target);
			throw new Error(`Not equal — the power sum differs from N by ${difference}.`);
		}
		const max = signedTerms.reduce(
			(current, value) => (absolute(value) > current ? absolute(value) : current),
			0n
		);
		const normalizedTerms = sortedSigned(signedTerms);
		return {
			left: normalizedTerms,
			right: [target],
			equation: `${formatSignedTerms(normalizedTerms)} = ${target}`,
			powerSum: target.toString(),
			maxTerm: Number(max)
		};
	}
	if (category.format === 'near_miss') {
		const left = parseSide(parts[0], category.exponent);
		if (left.length !== category.left_count || left.some((term) => term === 0n)) {
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
		if (right.length !== category.right_count || right.some((term) => term === 0n)) {
			throw new Error(
				`This category needs exactly ${category.right_count} positive ${category.right_count === 1 ? 'term' : 'terms'} before the residual.`
			);
		}
		requirePrimitive([...left, ...right]);
		const residual = rightMatch[2] === '+' ? 1n : -1n;
		const leftSum = left.reduce((total, value) => total + value ** BigInt(category.exponent), 0n);
		const rightSum =
			right.reduce((total, value) => total + value ** BigInt(category.exponent), 0n) + residual;
		if (leftSum !== rightSum) {
			const difference = absolute(leftSum - rightSum);
			throw new Error(`Not equal — the two sides differ by ${difference}.`);
		}
		const max = [...left, ...right].reduce(
			(current, value) => (value > current ? value : current),
			0n
		);
		const normalizedLeft = sorted(left);
		const normalizedRight = sorted(right);
		return {
			left: normalizedLeft,
			right: [...normalizedRight, residual],
			equation: `${normalizedLeft.map(String).join(' + ')} = ${normalizedRight.map(String).join(' + ')} ${residual > 0n ? '+' : '-'} 1`,
			powerSum: leftSum.toString(),
			maxTerm: Number(max)
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

	const sum = (values: bigint[]) =>
		values.reduce((total, value) => total + value ** BigInt(category.exponent), 0n);
	const leftSum = sum(left);
	const rightSum = sum(right);
	if (leftSum !== rightSum) {
		const difference = leftSum > rightSum ? leftSum - rightSum : rightSum - leftSum;
		throw new Error(`Not equal — the two power sums differ by ${difference.toString()}.`);
	}

	let normalizedLeft = sorted(left);
	let normalizedRight = sorted(right);
	if ([...left, ...right].every((term) => term === 0n)) {
		throw new Error('The all-zero identity is trivial and cannot be published.');
	}
	if (
		category.left_count === category.right_count &&
		compareTerms(normalizedLeft, normalizedRight) === 0
	) {
		throw new Error('A rearrangement of the same terms is a trivial identity.');
	}
	if (
		category.left_count === category.right_count &&
		compareTerms(normalizedLeft, normalizedRight) < 0
	) {
		[normalizedLeft, normalizedRight] = [normalizedRight, normalizedLeft];
	}
	const allTerms = [...left, ...right];
	const max = allTerms.reduce((current, value) => (value > current ? value : current), 0n);

	return {
		left: normalizedLeft,
		right: normalizedRight,
		equation: `${normalizedLeft.map(String).join(' + ')} = ${normalizedRight.map(String).join(' + ')}`,
		powerSum: leftSum.toString(),
		maxTerm: Number(max)
	};
}
