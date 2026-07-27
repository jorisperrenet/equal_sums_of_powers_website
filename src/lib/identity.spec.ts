import { describe, expect, it } from 'vitest';
import { formatIdentity, normalizeIdentity } from './identity';

describe('identity formatting', () => {
	it('sorts both sides and gives the larger equal-length side first', () => {
		expect(
			normalizeIdentity('[8,2]', '[1,9]', {
				exponent: 7,
				left_count: 2,
				right_count: 2,
				format: 'equality'
			})
		).toEqual({ left: ['9', '1'], right: ['8', '2'], residual: null });
	});

	it('keeps a near-miss residual last and sorts the power terms', () => {
		expect(
			formatIdentity('[3,10,5]', '[4,9,-1]', {
				exponent: 5,
				left_count: 3,
				right_count: 2,
				format: 'near_miss'
			})
		).toBe('10^5 + 5^5 + 3^5 = 9^5 + 4^5 - 1');
	});

	it('sorts signed target terms by absolute value', () => {
		expect(
			formatIdentity('[-2,10,-11,5]', '[17]', {
				exponent: 5,
				left_count: 4,
				right_count: 1,
				format: 'target'
			})
		).toBe('-11^5 + 10^5 + 5^5 - 2^5 = 17');
	});

	it('makes the greatest-absolute-value term positive for a zero target', () => {
		expect(
			formatIdentity('[-144,27,84,110,133]', '[0]', {
				exponent: 5,
				left_count: 5,
				right_count: 1,
				format: 'target'
			})
		).toBe('144^5 - 133^5 - 110^5 - 84^5 - 27^5 = 0');
	});
});
