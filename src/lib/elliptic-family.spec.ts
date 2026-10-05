import { describe, expect, it } from 'vitest';
import { ellipticFamilyK } from './elliptic-family';

describe('ellipticFamilyK', () => {
	it('finds k = 1 for the smallest Jacobi–Madden solution', () => {
		// 5400 − 2634 + 1770 + 955 = 5491
		expect(ellipticFamilyK(5491n, [5400n, 2634n, 1770n, 955n])).toBe('1');
	});

	it('finds an integer k with signs and order taken into account', () => {
		// e = a + 27(b + c + d) with (a, b, c, d) = (329580, −32420, −1911244, 2018095)
		expect(ellipticFamilyK(2339217n, [2018095n, 1911244n, 329580n, 32420n])).toBe('3');
	});

	it('finds a fractional k on a large solution', () => {
		expect(
			ellipticFamilyK(6979672262940660711812397183120932669712052957n, [
				6214055514363460635662277724212213227799603076n,
				4401817864091824284631155913006108077402758700n,
				4349694782462131107947288554302710777544241245n,
				3492398902524010879566685691799933449736157920n
			])
		).toBe('3/5');
	});

	it('returns null for a solution outside every family', () => {
		// The smallest solution of a⁴ + b⁴ + c⁴ + d⁴ = e⁴.
		expect(ellipticFamilyK(353n, [315n, 272n, 120n, 30n])).toBeNull();
	});
});
