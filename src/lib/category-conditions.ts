// Categories that record only solutions meeting a condition beyond the equation
// itself (migration 0037). Each entry names the condition for headings and chips
// and checks a verified, normalized solution: the left side holds the lone term
// when left_count is 1. scripts/check-database.mjs audits the same conditions.
//
// (4, 1, 4) is restricted too, to its elliptic-curve families, but that check
// lives in src/lib/elliptic-family.ts because it also records the family.

export type CategoryCondition = {
	/** Short form for chips, e.g. "7 ∤ a". */
	short: string;
	/** Phrase for headings and descriptions, e.g. "lone term prime to 7". */
	phrase: string;
	/** Explanation shown under the heading of the category page. */
	about?: string;
	/** Error message when a solution fails the condition, or null when it holds. */
	check: (left: bigint[], right: bigint[]) => string | null;
};

export const LONE_TERM_PRIME_TO_7_CATEGORY = '6-1-7-coprime-7';

export const CATEGORY_CONDITIONS: Record<string, CategoryCondition> = {
	[LONE_TERM_PRIME_TO_7_CATEGORY]: {
		short: '7 ∤ a',
		phrase: 'lone term prime to 7',
		about:
			'Most solutions of (6, 1, 7) have the lone term a divisible by 7. This restricted category is interesting for the study of possible solutions of (6, 1, 6), as the lone term there must be prime to 7.',
		check: (left) =>
			left[0] % 7n === 0n
				? `This category records only solutions whose lone term a is not divisible by 7, and ${left[0]} = 7 · ${left[0] / 7n}.`
				: null
	}
};

export function categoryCondition(categoryId: string): CategoryCondition | undefined {
	return CATEGORY_CONDITIONS[categoryId];
}
