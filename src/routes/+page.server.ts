import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { normalizeIdentity } from '$lib/identity';
import { parseAndVerify, type CategoryShape } from '$lib/server/equations';
import { TARGET_MAX, TARGET_MIN } from '$lib/target-range';
import type { D1Database } from '@cloudflare/workers-types';
import katex from 'katex';

const notationFormulas = {
	equalLabel: katex.renderToString('(n,a,b)', { displayMode: true }),
	equalEquation: katex.renderToString('x_1^n+\\cdots+x_a^n=y_1^n+\\cdots+y_b^n', {
		displayMode: true
	}),
	nearMissLabel: katex.renderToString('(n,a,b;\\,\\pm1)', { displayMode: true }),
	nearMissEquation: katex.renderToString('x_1^n+\\cdots+x_a^n=y_1^n+\\cdots+y_b^n\\pm1', {
		displayMode: true
	}),
	targetLabel: katex.renderToString('(n,k;\\,N)', { displayMode: true }),
	targetEquation: katex.renderToString('x_1^n+\\cdots+x_k^n=N', {
		displayMode: true
	}),
	targetRange: katex.renderToString(`${TARGET_MIN}\\le N\\le${TARGET_MAX}`, {
		displayMode: true
	}),
	unsignedSearchBounds: katex.renderToString('0\\le x_i<B', { displayMode: true }),
	signedSearchBounds: katex.renderToString('0\\le |x_i|<B', { displayMode: true })
};

type CategoryRow = CategoryShape & {
	notation: string | null;
	example_left_terms: string | null;
	example_right_terms: string | null;
	submission_count: number;
};

type SubmissionRow = {
	id: string;
	category_id: string;
	username: string;
	left_terms: string;
	right_terms: string;
	tool_name: string | null;
	tool_url: string | null;
	tool_reference_id: number | null;
	created_at: string;
};

type RecentSubmissionRow = SubmissionRow & {
	exponent: number;
	left_count: number;
	right_count: number;
	format: 'equality' | 'near_miss' | 'target';
	notation: string | null;
};

type SearchClaimRow = {
	id: string;
	category_id: string;
	username: string;
	lower_radius: string;
	upper_radius: string;
	search_type: 'exhaustive' | 'partial';
	tool_name: string;
	tool_url: string | null;
	tool_reference_id: number | null;
	comment: string | null;
	created_at: string;
};

type ResourceRow = {
	id: number;
	title: string;
	url: string;
	usage_count: number;
};

type TargetCoverageRow = {
	n: number;
	solution_count: number;
};

function validateUsername(username: string) {
	if (username.length < 2 || username.length > 32) {
		return 'Use a username between 2 and 32 characters.';
	}
	if (!/^[\p{L}\p{N}_. -]+$/u.test(username)) {
		return 'The username contains unsupported characters.';
	}
	return null;
}

function validateHttpUrl(value: string) {
	if (!value) return null;
	try {
		const parsedUrl = new URL(value);
		if (parsedUrl.protocol !== 'http:' && parsedUrl.protocol !== 'https:') {
			return 'Use a valid http or https link.';
		}
	} catch {
		return 'Use a valid http or https link.';
	}
	return null;
}

function serializeTerms(values: bigint[]) {
	return `[${values.join(',')}]`;
}

function identityKey(leftTerms: string, rightTerms: string, category: CategoryShape) {
	const normalized = normalizeIdentity(leftTerms, rightTerms, category);
	const right =
		category.format === 'near_miss'
			? [...normalized.right, normalized.residual!]
			: normalized.right;
	return `${JSON.stringify(normalized.left)}=${JSON.stringify(right)}`;
}

async function getCategories(db: D1Database) {
	const result = await db
		.prepare(
			`SELECT c.id, c.exponent, c.left_count, c.right_count,
			 c.format, c.notation,
			 (SELECT example.left_terms FROM submissions example
			  WHERE example.category_id = c.id
			  ORDER BY example.discovered_at ASC LIMIT 1) AS example_left_terms,
			 (SELECT example.right_terms FROM submissions example
			  WHERE example.category_id = c.id
			  ORDER BY example.discovered_at ASC LIMIT 1) AS example_right_terms,
			 COUNT(s.id) AS submission_count
			 FROM categories c LEFT JOIN submissions s ON s.category_id = c.id
			 GROUP BY c.id
			 ORDER BY (c.left_count + c.right_count) ASC, c.exponent DESC, c.left_count DESC`
		)
		.all<CategoryRow>();
	return result.results;
}

export const load: PageServerLoad = async ({ platform, url }) => {
	const pageSize = 100;
	const db = platform?.env.DB;
	const requested = url.searchParams.get('category');
	const showRecent = url.searchParams.get('view') === 'recent' || !requested;
	if (!db) {
		return {
			categories: [],
			submissions: [],
			searchClaims: [],
			recentResults: [],
			references: [],
			targetCoverage: [],
			selectedCategory: '7-4-4',
			showRecent,
			notationFormulas,
			page: 1,
			pageSize,
			sort: 'date' as const,
			selectedCount: 0,
			total: 0
		};
	}

	const categories = await getCategories(db);
	const selectedCategory = categories.some((category) => category.id === requested)
		? requested!
		: categories.some((category) => category.id === '7-4-4')
			? '7-4-4'
			: (categories[0]?.id ?? '7-4-4');
	const selectedCount = Number(
		categories.find((category) => category.id === selectedCategory)?.submission_count ?? 0
	);
	const selectedCategoryRow = categories.find((category) => category.id === selectedCategory);
	const requestedSort = url.searchParams.get('sort');
	const sort =
		requestedSort === 'date' ? 'date' : selectedCategoryRow?.format === 'target' ? 'n' : 'highest';
	const requestedPage = Number.parseInt(url.searchParams.get('page') ?? '1', 10);
	const lastPage = Math.max(1, Math.ceil(selectedCount / pageSize));
	const page = Number.isSafeInteger(requestedPage)
		? Math.min(Math.max(requestedPage, 1), lastPage)
		: 1;
	const submissionOrder =
		sort === 'n'
			? "CAST(json_extract(s.right_terms, '$[0]') AS INTEGER) ASC, s.discovered_at ASC"
			: sort === 'highest'
				? `MAX(
					(SELECT MAX(ABS(CAST(value AS INTEGER))) FROM json_each(s.left_terms)),
					(SELECT MAX(ABS(CAST(value AS INTEGER))) FROM json_each(s.right_terms))
				  ) ASC, s.discovered_at ASC`
				: 's.discovered_at DESC';
	const submissions = await db
		.prepare(
			`SELECT s.id, s.category_id, contributor.name AS username, s.left_terms, s.right_terms,
			 COALESCE(tool.title, s.tool_text) AS tool_name,
			 tool.url AS tool_url,
			 tool.id AS tool_reference_id,
			 s.discovered_at AS created_at
			 FROM submissions s
			 JOIN contributors contributor ON contributor.id = s.contributor_id
			 LEFT JOIN submission_resources str ON str.submission_id = s.id AND str.role = 'tool'
			 LEFT JOIN resources tool ON tool.id = str.resource_id
			 WHERE s.category_id = ? ORDER BY ${submissionOrder} LIMIT ? OFFSET ?`
		)
		.bind(selectedCategory, pageSize, (page - 1) * pageSize)
		.all<SubmissionRow>();
	const searchClaims = showRecent
		? await db
				.prepare(
					`SELECT c.id, c.category_id, contributor.name AS username, c.lower_radius, c.upper_radius, c.search_type,
					 COALESCE(r.title, c.tool_text, '') AS tool_name, r.url AS tool_url,
					 r.id AS tool_reference_id, c.comment, c.created_at
					 FROM search_claims c
					 JOIN contributors contributor ON contributor.id = c.contributor_id
					 LEFT JOIN search_claim_resources cr ON cr.search_claim_id = c.id
					 LEFT JOIN resources r ON r.id = cr.resource_id
					 ORDER BY c.created_at DESC LIMIT 100`
				)
				.all<SearchClaimRow>()
		: { results: [] as SearchClaimRow[] };
	const recentResults = showRecent
		? await db
				.prepare(
					`SELECT s.id, s.category_id, contributor.name AS username,
					 s.left_terms, s.right_terms,
					 COALESCE(tool.title, s.tool_text) AS tool_name,
					 tool.url AS tool_url, tool.id AS tool_reference_id,
					 s.discovered_at AS created_at,
					 category.exponent, category.left_count, category.right_count,
					 category.format, category.notation
					 FROM submissions s
					 JOIN contributors contributor ON contributor.id = s.contributor_id
					 JOIN categories category ON category.id = s.category_id
					 LEFT JOIN submission_resources str
					   ON str.submission_id = s.id AND str.role = 'tool'
					 LEFT JOIN resources tool ON tool.id = str.resource_id
					 ORDER BY s.discovered_at DESC LIMIT 5`
				)
				.all<RecentSubmissionRow>()
		: { results: [] as RecentSubmissionRow[] };
	const references = await db
		.prepare(
			`SELECT r.id, r.title, r.url,
			 (SELECT COUNT(DISTINCT submission_id) FROM submission_resources sr WHERE sr.resource_id = r.id) +
			 (SELECT COUNT(DISTINCT search_claim_id) FROM search_claim_resources cr WHERE cr.resource_id = r.id) +
			 (SELECT COUNT(DISTINCT category_id) FROM category_resources gr WHERE gr.resource_id = r.id) AS usage_count
			 FROM resources r ORDER BY r.id ASC`
		)
		.all<ResourceRow>();
	const targetCoverage =
		selectedCategoryRow?.format === 'target'
			? await db
					.prepare(
						`SELECT CAST(json_extract(right_terms, '$[0]') AS INTEGER) AS n, COUNT(*) AS solution_count
						 FROM submissions WHERE category_id = ?
						 GROUP BY json_extract(right_terms, '$[0]') ORDER BY n ASC`
					)
					.bind(selectedCategory)
					.all<TargetCoverageRow>()
			: { results: [] as TargetCoverageRow[] };
	const total = categories.reduce((sum, category) => sum + Number(category.submission_count), 0);

	return {
		categories,
		submissions: submissions.results,
		searchClaims: searchClaims.results,
		recentResults: recentResults.results,
		references: references.results,
		targetCoverage: targetCoverage.results,
		selectedCategory,
		sort,
		showRecent,
		notationFormulas,
		page,
		pageSize,
		selectedCount,
		total
	};
};

export const actions: Actions = {
	submitIdentity: async ({ request, platform }) => {
		const db = platform?.env.DB;
		if (!db)
			return fail(503, {
				kind: 'identity' as const,
				message: 'The database is not available in this environment.',
				categoryId: '',
				username: '',
				equationInput: ''
			});

		const data = await request.formData();
		const categoryId = String(data.get('category') ?? '');
		const username = String(data.get('username') ?? '').trim();
		const equationInput = String(data.get('equation') ?? '').trim();
		const resultToolName = String(data.get('resultToolName') ?? '').trim();
		const resultToolUrl = String(data.get('resultToolUrl') ?? '').trim();
		const website = String(data.get('website') ?? '');
		if (website)
			return fail(400, {
				kind: 'identity' as const,
				message: 'The submission could not be accepted.',
				categoryId,
				username,
				equationInput
			});
		const usernameError = validateUsername(username);
		if (usernameError) {
			return fail(400, {
				kind: 'identity' as const,
				message: usernameError,
				categoryId,
				username,
				equationInput
			});
		}
		if (resultToolName.length > 80) {
			return fail(400, {
				kind: 'identity' as const,
				message: 'Keep the tool or program name to 80 characters.',
				categoryId,
				username,
				equationInput
			});
		}
		if (resultToolUrl.length > 300) {
			return fail(400, {
				kind: 'identity' as const,
				message: 'The tool or source-code link is too long.',
				categoryId,
				username,
				equationInput
			});
		}
		const resultUrlError = validateHttpUrl(resultToolUrl);
		if (resultUrlError) {
			return fail(400, {
				kind: 'identity' as const,
				message: resultUrlError,
				categoryId,
				username,
				equationInput
			});
		}
		if (resultToolUrl && !resultToolName) {
			return fail(400, {
				kind: 'identity' as const,
				message: 'Add a name for the linked tool or source code.',
				categoryId,
				username,
				equationInput
			});
		}
		const equationLines = equationInput
			.split(/\r?\n/)
			.map((line) => line.trim())
			.filter(Boolean);
		if (equationLines.length === 0) {
			return fail(400, {
				kind: 'identity' as const,
				message: 'Enter at least one equation.',
				categoryId,
				username,
				equationInput
			});
		}
		if (equationLines.length > 50) {
			return fail(400, {
				kind: 'identity' as const,
				message: 'Submit at most 50 equations at a time.',
				categoryId,
				username,
				equationInput
			});
		}

		const category = await db
			.prepare('SELECT id, exponent, left_count, right_count, format FROM categories WHERE id = ?')
			.bind(categoryId)
			.first<CategoryShape>();
		if (!category)
			return fail(400, {
				kind: 'identity' as const,
				message: 'Choose a valid category.',
				categoryId,
				username,
				equationInput
			});

		const verifiedResults = [];
		for (const [index, line] of equationLines.entries()) {
			try {
				verifiedResults.push(parseAndVerify(line, category));
			} catch (error) {
				const reason =
					error instanceof Error ? error.message : 'That equation could not be verified.';
				return fail(400, {
					kind: 'identity' as const,
					message: `Line ${index + 1}: ${reason}`,
					categoryId,
					username,
					equationInput
				});
			}
		}
		const serializedResults = verifiedResults.map((result) => ({
			left: serializeTerms(result.left),
			right: serializeTerms(result.right)
		}));
		if (
			new Set(serializedResults.map((result) => `${result.left}=${result.right}`)).size !==
			serializedResults.length
		) {
			return fail(400, {
				kind: 'identity' as const,
				message: 'The submitted list contains the same identity more than once.',
				categoryId,
				username,
				equationInput
			});
		}
		const existing = await db
			.prepare('SELECT left_terms, right_terms FROM submissions WHERE category_id = ?')
			.bind(category.id)
			.all<{ left_terms: string; right_terms: string }>();
		const existingKeys = new Set(
			existing.results.map((result) => identityKey(result.left_terms, result.right_terms, category))
		);
		if (
			serializedResults.some((result) =>
				existingKeys.has(identityKey(result.left, result.right, category))
			)
		) {
			return fail(409, {
				kind: 'identity' as const,
				message: 'At least one result in that list is already on the leaderboard.',
				categoryId,
				username,
				equationInput
			});
		}

		try {
			const submissionIds = verifiedResults.map(() => crypto.randomUUID());
			const statement = db.prepare(
				`INSERT INTO submissions
					 (id, category_id, contributor_id, left_terms, right_terms, tool_text)
					 SELECT ?, ?, id, ?, ?, ? FROM contributors WHERE name = ?`
			);
			const statements = [
				db.prepare('INSERT OR IGNORE INTO contributors (name) VALUES (?)').bind(username),
				...verifiedResults.map((verified, index) =>
					statement.bind(
						submissionIds[index],
						category.id,
						serializedResults[index].left,
						serializedResults[index].right,
						resultToolUrl ? null : resultToolName || null,
						username
					)
				)
			];
			if (resultToolUrl) {
				statements.push(
					db
						.prepare(`INSERT OR IGNORE INTO resources (title, url) VALUES (?, ?)`)
						.bind(resultToolName, resultToolUrl)
				);
				for (const submissionId of submissionIds) {
					statements.push(
						db
							.prepare(
								`INSERT INTO submission_resources (submission_id, resource_id, role)
								 SELECT ?, id, 'tool' FROM resources WHERE url = ?`
							)
							.bind(submissionId, resultToolUrl)
					);
				}
			}
			await db.batch(statements);
		} catch (error) {
			if (error instanceof Error && /unique/i.test(error.message)) {
				return fail(409, {
					kind: 'identity' as const,
					message: 'At least one result in that list is already on the leaderboard.',
					categoryId,
					username,
					equationInput
				});
			}
			throw error;
		}

		return {
			kind: 'identity' as const,
			success: true,
			message: `${verifiedResults.length} ${verifiedResults.length === 1 ? 'result' : 'results'} verified exactly and added to the public leaderboard.`,
			categoryId,
			username: '',
			equationInput: ''
		};
	},

	claimSearch: async ({ request, platform }) => {
		const db = platform?.env.DB;
		if (!db) {
			return fail(503, {
				kind: 'claim' as const,
				message: 'The database is not available in this environment.'
			});
		}

		const data = await request.formData();
		const categoryId = String(data.get('category') ?? '');
		const username = String(data.get('username') ?? '').trim();
		const rawLowerRadius = String(data.get('lowerRadius') ?? '')
			.trim()
			.replaceAll(',', '');
		const rawUpperRadius = String(data.get('upperRadius') ?? '')
			.trim()
			.replaceAll(',', '');
		const searchType = String(data.get('searchType') ?? '');
		const toolName = String(data.get('toolName') ?? '').trim();
		const toolUrl = String(data.get('toolUrl') ?? '').trim();
		const comment = String(data.get('comment') ?? '').trim();
		const website = String(data.get('claimWebsite') ?? '');
		const claimValues = {
			kind: 'claim' as const,
			categoryId,
			username,
			lowerRadius: rawLowerRadius,
			upperRadius: rawUpperRadius,
			searchType,
			toolName,
			toolUrl,
			comment
		};

		if (website) return fail(400, { ...claimValues, message: 'The claim could not be accepted.' });
		const usernameError = validateUsername(username);
		if (usernameError) return fail(400, { ...claimValues, message: usernameError });
		if (!/^\d{1,50}$/.test(rawLowerRadius) || BigInt(rawLowerRadius) < 0n) {
			return fail(400, { ...claimValues, message: 'Enter a non-negative lower radius.' });
		}
		if (!/^\d{1,50}$/.test(rawUpperRadius) || BigInt(rawUpperRadius) < 1n) {
			return fail(400, { ...claimValues, message: 'Enter a positive upper radius.' });
		}
		if (BigInt(rawLowerRadius) >= BigInt(rawUpperRadius)) {
			return fail(400, {
				...claimValues,
				message: 'The lower radius must be below the upper radius.'
			});
		}
		if (searchType !== 'exhaustive' && searchType !== 'partial') {
			return fail(400, { ...claimValues, message: 'Choose a valid search type.' });
		}
		if (toolName.length < 2 || toolName.length > 80) {
			return fail(400, { ...claimValues, message: 'Name the tool or program in 2–80 characters.' });
		}
		if (comment.length > 500) {
			return fail(400, { ...claimValues, message: 'Keep the search notes to 500 characters.' });
		}
		if (toolUrl.length > 300) {
			return fail(400, { ...claimValues, message: 'The tool link is too long.' });
		}
		const toolUrlError = validateHttpUrl(toolUrl);
		if (toolUrlError) return fail(400, { ...claimValues, message: toolUrlError });
		const category = await db
			.prepare('SELECT id FROM categories WHERE id = ?')
			.bind(categoryId)
			.first<{ id: string }>();
		if (!category) return fail(400, { ...claimValues, message: 'Choose a valid category.' });

		const normalizedLowerRadius = BigInt(rawLowerRadius).toString();
		const normalizedUpperRadius = BigInt(rawUpperRadius).toString();
		try {
			const claimId = crypto.randomUUID();
			const statements = [
				db.prepare('INSERT OR IGNORE INTO contributors (name) VALUES (?)').bind(username),
				db
					.prepare(
						`INSERT INTO search_claims
					 (id, category_id, contributor_id, lower_radius, upper_radius,
					  search_type, tool_text, comment)
					 SELECT ?, ?, id, ?, ?, ?, ?, ? FROM contributors WHERE name = ?`
					)
					.bind(
						claimId,
						categoryId,
						normalizedLowerRadius,
						normalizedUpperRadius,
						searchType,
						toolUrl ? null : toolName,
						comment || null,
						username
					)
			];
			if (toolUrl) {
				statements.push(
					db
						.prepare(`INSERT OR IGNORE INTO resources (title, url) VALUES (?, ?)`)
						.bind(toolName, toolUrl),
					db
						.prepare(
							`INSERT INTO search_claim_resources (search_claim_id, resource_id)
							 SELECT ?, id FROM resources WHERE url = ?`
						)
						.bind(claimId, toolUrl)
				);
			}
			await db.batch(statements);
		} catch (error) {
			if (error instanceof Error && /unique/i.test(error.message)) {
				return fail(409, { ...claimValues, message: 'That search claim is already recorded.' });
			}
			throw error;
		}

		return {
			kind: 'claim' as const,
			success: true,
			message: 'Search coverage claim published.',
			categoryId
		};
	}
};
