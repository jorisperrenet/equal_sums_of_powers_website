import { describe, expect, it } from 'vitest';
import { parseStoredTerms, serializeTerms } from './terms';

describe('stored terms', () => {
	it('stores safe integers as numbers and larger ones as digit strings', () => {
		const big = 9007199254740993n;
		expect(serializeTerms([9007199254740991n, -big, 3n])).toBe(
			'[9007199254740991,"-9007199254740993",3]'
		);
		expect(parseStoredTerms('[9007199254740991,"-9007199254740993",3]')).toEqual([
			9007199254740991n,
			-big,
			3n
		]);
	});

	it('rejects every other form, so each term has one stored form', () => {
		expect(() => parseStoredTerms('["12"]')).toThrow(/canonical/);
		expect(() => parseStoredTerms('["09007199254740993"]')).toThrow(/canonical/);
		expect(() => parseStoredTerms('[9007199254740993]')).toThrow(/safe integer/);
		expect(() => parseStoredTerms('[1.5]')).toThrow(/safe integer/);
	});
});
