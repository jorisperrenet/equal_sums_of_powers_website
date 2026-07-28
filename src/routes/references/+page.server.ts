import type { PageServerLoad } from './$types';

type ReferenceRow = {
	id: number;
	title: string;
	url: string;
	usage_count: number;
};

export const load: PageServerLoad = async ({ platform }) => {
	const references = platform?.env.DB
		? await platform.env.DB.prepare(
				`SELECT r.id, r.title, r.url,
				 (SELECT COUNT(DISTINCT submission_id) FROM submission_resources sr WHERE sr.resource_id = r.id) +
				 (SELECT COUNT(DISTINCT search_claim_id) FROM search_claim_resources cr WHERE cr.resource_id = r.id) +
				 (SELECT COUNT(DISTINCT category_id) FROM category_resources gr WHERE gr.resource_id = r.id) AS usage_count
				 FROM resources r ORDER BY r.id ASC`
			).all<ReferenceRow>()
		: { results: [] as ReferenceRow[] };

	return { references: references.results };
};
