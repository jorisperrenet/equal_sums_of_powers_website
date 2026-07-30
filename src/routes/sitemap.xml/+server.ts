import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ platform }) => {
	const rows = platform?.env.DB
		? await platform.env.DB.prepare(
				`SELECT c.id, c.exponent, COUNT(s.id) AS submission_count
				 FROM categories c
				 LEFT JOIN submissions s ON s.category_id = c.id
				 GROUP BY c.id
				 ORDER BY c.exponent DESC, c.id`
			).all<{
				id: string;
				exponent: number;
				submission_count: number;
			}>()
		: { results: [] };
	const urls = [
		'https://powersums.jorisperrenet.com/',
		'https://powersums.jorisperrenet.com/references/'
	];
	for (const { id, exponent, submission_count } of rows.results) {
		const path = `https://powersums.jorisperrenet.com/${exponent}${exponent === 1 ? 'st' : exponent === 2 ? 'nd' : exponent === 3 ? 'rd' : 'th'}-powers/${id}/`;
		const pages = Math.max(1, Math.ceil(Number(submission_count) / 100));
		for (let page = 1; page <= pages; page += 1) {
			urls.push(page === 1 ? path : `${path}?page=${page}`);
		}
	}
	const body = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls
		.map((url) => `  <url><loc>${url}</loc></url>`)
		.join('\n')}\n</urlset>\n`;
	return new Response(body, {
		headers: {
			'content-type': 'application/xml; charset=utf-8',
			'cache-control': 'public, max-age=3600'
		}
	});
};
