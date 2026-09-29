import { version as buildVersion } from '$app/environment';

// Cached entries never go stale: the key carries site_version.version, which
// triggers bump on every change to displayed data (migration 0027), and the
// build version, so a deploy never serves results shaped for older code.
// Entries for older versions are simply never requested again and age out.
const MAX_AGE_SECONDS = 30 * 24 * 60 * 60;

export type QueryCache = <T>(key: string, compute: () => Promise<T>) => Promise<T>;

// A read-through cache for D1 query results, in the Cloudflare Cache API of the
// data center serving the request. Each request pays one D1 read for the data
// version and nothing more for every cached piece. Without the Cache API (the
// dev server, *.workers.dev) or before migration 0027 is applied, every piece is
// computed directly, exactly as before caching existed.
export function createQueryCache(platform: App.Platform | undefined, origin: string): QueryCache {
	const cache = platform?.caches?.default;
	const db = platform?.env.DB;
	let dataVersion: Promise<number | null> | undefined;

	return async (key, compute) => {
		if (!cache || !db) return compute();
		dataVersion ??= db
			.prepare('SELECT version FROM site_version WHERE id = 1')
			.first<number>('version')
			.catch(() => null);
		const version = await dataVersion;
		if (version === null) return compute();

		const cacheKey = `${origin}/__cache/${buildVersion}/${version}/${key}`;
		const hit = await cache.match(cacheKey);
		if (hit) return hit.json();

		const value = await compute();
		const response = new Response(JSON.stringify(value), {
			headers: {
				'content-type': 'application/json',
				'cache-control': `public, max-age=${MAX_AGE_SECONDS}`
			}
		});
		// The DOM and workers-types Response declarations differ; at runtime they are one class.
		const put = cache.put(cacheKey, response as unknown as Parameters<typeof cache.put>[1]);
		platform!.ctx.waitUntil(put);
		return value;
	};
}
