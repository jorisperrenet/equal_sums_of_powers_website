import { describe, expect, it } from 'vitest';
import { parseAndVerify } from './equations';

const category = { id: '7-4-4', exponent: 7, left_count: 4, right_count: 4 };

describe('parseAndVerify', () => {
	it('parses a category prefix and verifies exact seventh powers', () => {
		const result = parseAndVerify('(7,4,4) 2816+2703+1831+1489=3018+2183+1600+274', category);
		expect(result.maxTerm).toBe(3018);
		expect(result.powerSum).toBe('2543620023809369754347383');
	});

	it('rejects an incorrect equation with its exact difference', () => {
		expect(() => parseAndVerify('1+2+3+4=1+2+3+5', category)).toThrow(/differ by/);
	});

	it('rejects the wrong number of terms', () => {
		expect(() => parseAndVerify('1+2+3=1+2+3', category)).toThrow(/needs 4 terms/);
	});

	it('rejects a mismatched category prefix', () => {
		expect(() =>
			parseAndVerify('(5,4,4) 2816+2703+1831+1489=3018+2183+1600+274', category)
		).toThrow(/does not match/);
	});

	it('rejects trivial rearrangements', () => {
		expect(() => parseAndVerify('1+2+3+4=4+3+2+1', category)).toThrow(/trivial identity/);
	});

	it('rejects a valid but non-primitive scaled identity', () => {
		expect(() => parseAndVerify('5632+5406+3662+2978=6036+4366+3200+548', category)).toThrow(
			/not primitive/
		);
	});

	it('verifies signed sums with an integer target', () => {
		const targetCategory = {
			id: '5-5-n',
			exponent: 5,
			left_count: 5,
			right_count: 1,
			format: 'target' as const
		};
		const result = parseAndVerify('(5,5;N) 49=-22403+21596+15669+4698-4001', targetCategory);
		expect(result.powerSum).toBe('49');
		expect(result.maxTerm).toBe(22403);
	});

	it('limits target N to the public archive range', () => {
		const targetCategory = {
			id: '3-3-n',
			exponent: 3,
			left_count: 3,
			right_count: 1,
			format: 'target' as const
		};
		expect(() => parseAndVerify('(3,3;N) 5001=10+1+0', targetCategory)).toThrow(
			/between 0 and 5000/
		);
	});

	it.each([
		{ id: '7-7-n', exponent: 7, termCount: 7 },
		{ id: '9-9-n', exponent: 9, termCount: 9 }
	])('verifies signed sums in $id', ({ id, exponent, termCount }) => {
		const targetCategory = {
			id,
			exponent,
			left_count: termCount,
			right_count: 1,
			format: 'target' as const
		};
		const zeros = Array.from({ length: termCount - 2 }, () => '0').join('+');
		const result = parseAndVerify(`(${exponent},${termCount};N) 0=1-1+${zeros}`, targetCategory);
		expect(result.powerSum).toBe('0');
		expect(result.left).toHaveLength(termCount);
	});

	it('verifies both residual signs in the special quintic near-miss category', () => {
		const nearMissCategory = {
			id: '5-4-1-pm1',
			exponent: 5,
			left_count: 4,
			right_count: 1,
			format: 'near_miss' as const
		};
		const positive = parseAndVerify('(5,4,1;±1) 645+1523+1722+2506=2615+1', nearMissCategory);
		expect(positive.right).toEqual([2615n, 1n]);
		expect(() => parseAndVerify('1+1+1+1=1-1', nearMissCategory)).toThrow(/differ by/);
	});

	it('treats the fixed 1 as a residual in the three-to-two quintic category', () => {
		const nearMissCategory = {
			id: '5-3-2-pm1',
			exponent: 5,
			left_count: 3,
			right_count: 2,
			format: 'near_miss' as const
		};
		const result = parseAndVerify('(5,3,2;±1) 38+47+123=89+118+1', nearMissCategory);
		expect(result.right).toEqual([118n, 89n, 1n]);
	});
});
