import type { D1Database } from '@cloudflare/workers-types';
import type { RequestHandler } from './$types';
import { ELLIPTIC_FAMILY_CATEGORY, formatFamilies, isFamilyLabel } from '$lib/elliptic-family';
import { formatIdentity, type IdentityShape } from '$lib/identity';
import { createQueryCache } from '$lib/server/cache';

type CategoryRow = IdentityShape & {
	id: string;
	format: 'equality' | 'near_miss' | 'target';
};

type ExportRow = {
	left_terms: string;
	right_terms: string;
	username: string;
	discovered_at: string;
	tool_name: string | null;
	tool_url: string | null;
	family_k: string | null;
};

function csvCell(value: string) {
	return `"${value.replaceAll('"', '""')}"`;
}

function csvRow(values: string[]) {
	return values.map(csvCell).join(',');
}

function dateOnly(value: string) {
	return value.slice(0, 10);
}

export const GET: RequestHandler = async ({ platform, url }) => {
	const db = platform?.env.DB as D1Database | undefined;
	if (!db) return new Response('The database is not available.', { status: 503 });

	const categoryId = url.searchParams.get('category') ?? '';
	const category = await db
		.prepare('SELECT id, exponent, left_count, right_count, format FROM categories WHERE id = ?')
		.bind(categoryId)
		.first<CategoryRow>();
	if (!category) return new Response('Unknown category.', { status: 404 });

	const sort =
		url.searchParams.get('sort') === 'date'
			? 'date'
			: category.format === 'target'
				? 'n'
				: 'highest';
	// Same index-backed orderings as the leaderboard page (migration 0023).
	const order =
		sort === 'n'
			? "CAST(json_extract(s.right_terms, '$[0]') AS INTEGER) ASC, s.discovered_at ASC, s.id ASC"
			: sort === 'highest'
				? 's.max_term ASC, s.discovered_at ASC, s.id ASC'
				: 's.discovered_at DESC, s.id DESC';
	// Like the leaderboard, ?k=n/m or ?k=a=b keeps one elliptic family.
	const hasFamilies = category.id === ELLIPTIC_FAMILY_CATEGORY;
	const requestedFamily = url.searchParams.get('k');
	const family =
		hasFamilies && requestedFamily && isFamilyLabel(requestedFamily) ? requestedFamily : null;
	const [familyCondition, familyBindings] =
		family === null ? ['', []] : ['AND s.family_k IS NOT NULL AND s.family_k = ?', [family]];
	const cached = createQueryCache(platform, url.origin);
	const results = await cached(`export/${category.id}/${sort}${family ? `/k=${family}` : ''}`, () =>
		db
			.prepare(
				`SELECT s.left_terms, s.right_terms, contributor.name AS username,
			 s.discovered_at, COALESCE(tool.title, s.tool_text) AS tool_name,
			 tool.url AS tool_url, s.family_k
			 FROM submissions s
			 JOIN contributors contributor ON contributor.id = s.contributor_id
			 LEFT JOIN submission_resources str
			   ON str.submission_id = s.id AND str.role = 'tool'
			 LEFT JOIN resources tool ON tool.id = str.resource_id
			 WHERE s.category_id = ? ${familyCondition} ORDER BY ${order}`
			)
			.bind(category.id, ...familyBindings)
			.all<ExportRow>()
	);

	const rows = [
		csvRow(['Identity', ...(hasFamilies ? ['Family'] : []), 'Contributor', 'Date', 'Tools/Source'])
	];
	for (const result of results.results) {
		const tool = result.tool_url
			? `${result.tool_name || 'Tool / source'} — ${result.tool_url}`
			: (result.tool_name ?? '');
		rows.push(
			csvRow([
				formatIdentity(result.left_terms, result.right_terms, category),
				...(hasFamilies ? [result.family_k ? formatFamilies(result.family_k) : ''] : []),
				result.username,
				dateOnly(result.discovered_at),
				tool
			])
		);
	}

	return new Response(`${rows.join('\r\n')}\r\n`, {
		headers: {
			'content-type': 'text/csv; charset=utf-8',
			'content-disposition': `attachment; filename="${category.id}${family ? `-k-${family.replace('/', '-')}` : ''}-leaderboard.csv"`,
			'cache-control': 'public, max-age=300'
		}
	});
};
