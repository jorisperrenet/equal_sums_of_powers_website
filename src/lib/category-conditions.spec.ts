import { describe, expect, it } from 'vitest';
import { LONE_TERM_PRIME_TO_7_CATEGORY, categoryCondition } from './category-conditions';

describe('category conditions', () => {
	const condition = categoryCondition(LONE_TERM_PRIME_TO_7_CATEGORY)!;

	it('accepts a lone term prime to 7 and rejects a multiple of 7', () => {
		expect(condition.check([1142n], [])).toBeNull();
		expect(condition.check([1141n], [])).toMatch(/1141 = 7 · 163/);
	});

	it('leaves other categories unrestricted', () => {
		expect(categoryCondition('6-3-3')).toBeUndefined();
	});
});
