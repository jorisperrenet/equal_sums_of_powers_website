import { describe, expect, it } from 'vitest';
import { parseAndVerify } from './equations';

const category = { id: '7-4-4', exponent: 7, left_count: 4, right_count: 4 };

describe('parseAndVerify', () => {
	it('parses a category prefix and verifies exact seventh powers', () => {
		const result = parseAndVerify('(7,4,4) 2816+2703+1831+1489=3018+2183+1600+274', category);
		expect(result.maxTerm).toBe(3018n);
		expect(result.powerSum).toBe('2543620023809369754347383');
	});

	it('rejects an incorrect equation with its exact difference', () => {
		expect(() => parseAndVerify('1+2+3+4=1+2+3+5', category)).toThrow(/differ by/);
	});

	it('accepts the sides in either order when their lengths differ', () => {
		const quartic = { id: '4-1-4', exponent: 4, left_count: 1, right_count: 4 };
		expect(parseAndVerify('30+120+272+315=353', quartic).equation).toBe(
			'353 = 315 + 272 + 120 + 30'
		);
		expect(parseAndVerify('353=30+120+272+315', quartic).equation).toBe(
			'353 = 315 + 272 + 120 + 30'
		);
	});

	it('rejects the wrong number of terms', () => {
		expect(() => parseAndVerify('1+2+3=1+2+3', category)).toThrow(/needs 4 terms/);
	});

	it('verifies terms of any size up to 100 digits', () => {
		const quartic = { id: '4-1-4', exponent: 4, left_count: 1, right_count: 4 };
		const result = parseAndVerify(
			'6979672262940660711812397183120932669712052957 = 6214055514363460635662277724212213227799603076 + 4401817864091824284631155913006108077402758700 + 4349694782462131107947288554302710777544241245 + 3492398902524010879566685691799933449736157920',
			quartic
		);
		expect(result.maxTerm).toBe(6979672262940660711812397183120932669712052957n);
		expect(result.right[0]).toBe(6214055514363460635662277724212213227799603076n);
		expect(() => parseAndVerify(`${'9'.repeat(101)}+1+2+3=1+2+3+4`, category)).toThrow(
			/at most 100 digits/
		);
	});

	it('reads superscript exponents of any length', () => {
		const tenth = { id: '10-1-2', exponent: 10, left_count: 1, right_count: 2 };
		expect(() => parseAndVerify('3¹⁰=2¹⁰+1¹⁰', tenth)).toThrow(/differ by/);
		expect(() => parseAndVerify('3¹¹=2¹¹+1¹¹', tenth)).toThrow(/exponent must be 10/);
		expect(parseAndVerify('2816⁷+2703⁷+1831⁷+1489⁷=3018⁷+2183⁷+1600⁷+274⁷', category).maxTerm).toBe(
			3018n
		);
	});

	it('rejects a mismatched category prefix', () => {
		expect(() =>
			parseAndVerify('(5,4,4) 2816+2703+1831+1489=3018+2183+1600+274', category)
		).toThrow(/does not match/);
	});

	it('rejects trivial rearrangements', () => {
		expect(() => parseAndVerify('1+2+3+4=4+3+2+1', category)).toThrow(/trivial identity/);
	});

	it('rejects nonzero bases that occur on both sides, including repeated occurrences', () => {
		const unequalCategory = {
			id: '3-4-4',
			exponent: 3,
			left_count: 4,
			right_count: 4
		};
		expect(() => parseAndVerify('1+12+5+5=9+10+5+5', unequalCategory)).toThrow(/both sides/);
	});

	it('rejects zero terms that pad a solution of a smaller category', () => {
		const paddedCategory = {
			id: '8-4-5',
			exponent: 8,
			left_count: 4,
			right_count: 5
		};
		expect(() =>
			parseAndVerify('3113+2012+1953+861=2823+2767+2557+1128+0', paddedCategory)
		).toThrow(/positive/);
		expect(() =>
			parseAndVerify('1+12+0=9+10+0', { id: '3-3-3', exponent: 3, left_count: 3, right_count: 3 })
		).toThrow(/positive/);
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
		expect(result.maxTerm).toBe(22403n);
	});

	it('accepts a non-primitive signed sum for a nonzero integer target', () => {
		const targetCategory = {
			id: '3-3-n',
			exponent: 3,
			left_count: 3,
			right_count: 1,
			format: 'target' as const
		};
		const result = parseAndVerify('(3,3;N) 16=2+2+0', targetCategory);
		expect(result.equation).toBe('2 + 2 + 0 = 16');
	});

	it('still rejects a non-primitive signed sum when the target is zero', () => {
		const targetCategory = {
			id: '3-4-n',
			exponent: 3,
			left_count: 4,
			right_count: 1,
			format: 'target' as const
		};
		expect(() => parseAndVerify('(3,4;N) 0=6+8+10-12', targetCategory)).toThrow(/not primitive/);
	});

	it('automatically makes the greatest-absolute-value term positive for a zero target', () => {
		const targetCategory = {
			id: '5-5-n',
			exponent: 5,
			left_count: 5,
			right_count: 1,
			format: 'target' as const
		};
		const result = parseAndVerify('0=-144+133+110+84+27', targetCategory);
		expect(result.left).toEqual([144n, -133n, -110n, -84n, -27n]);
		expect(result.equation).toBe('144 - 133 - 110 - 84 - 27 = 0');
	});

	it('rejects signed target terms that cancel each other', () => {
		const targetCategory = {
			id: '5-5-n',
			exponent: 5,
			left_count: 5,
			right_count: 1,
			format: 'target' as const
		};
		expect(() => parseAndVerify('3=1+315-315+1+1', targetCategory)).toThrow(/cancel/);
	});

	it('limits target N to the public archive range', () => {
		const targetCategory = {
			id: '3-3-n',
			exponent: 3,
			left_count: 3,
			right_count: 1,
			format: 'target' as const
		};
		expect(() => parseAndVerify('(3,3;N) 2501=10+1+0', targetCategory)).toThrow(
			/between 0 and 2500/
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
		const zeros = Array.from({ length: termCount - 1 }, () => '0').join('+');
		const result = parseAndVerify(`(${exponent},${termCount};N) 1=1+${zeros}`, targetCategory);
		expect(result.powerSum).toBe('1');
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

	it('rejects a nonzero base on both sides of a near miss but ignores the residual', () => {
		const nearMissCategory = {
			id: '5-3-2-pm1',
			exponent: 5,
			left_count: 3,
			right_count: 2,
			format: 'near_miss' as const
		};
		expect(() => parseAndVerify('172+1+1=172+1+1', nearMissCategory)).toThrow(/both sides/);
		const result = parseAndVerify('38+47+123=89+118+1', nearMissCategory);
		expect(result.right.at(-1)).toBe(1n);
	});
});
