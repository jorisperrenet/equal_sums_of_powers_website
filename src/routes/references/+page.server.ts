import type { PageServerLoad } from './$types';
import { createQueryCache } from '$lib/server/cache';

type ReferenceRow = {
	id: number;
	title: string;
	url: string;
	usage_count: number;
};

export const load: PageServerLoad = async ({ platform, url }) => {
	const db = platform?.env.DB;
	const cached = createQueryCache(platform, url.origin);
	const references = db
		? await cached('references-page', () =>
				db
					.prepare(
						// Submission citations are counted by triggers (migration 0025); the
						// claim and category link tables are small enough to count live.
						`SELECT r.id, r.title, r.url,
				 COALESCE(sc.submission_count, 0) +
				 (SELECT COUNT(DISTINCT search_claim_id) FROM search_claim_resources cr WHERE cr.resource_id = r.id) +
				 (SELECT COUNT(DISTINCT category_id) FROM category_resources gr WHERE gr.resource_id = r.id) AS usage_count
				 FROM resources r LEFT JOIN resource_submission_counts sc ON sc.resource_id = r.id
				 ORDER BY r.id ASC`
					)
					.all<ReferenceRow>()
			)
		: { results: [] as ReferenceRow[] };

	return { references: references.results };
};
