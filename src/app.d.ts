import type {
	D1Database,
	ExecutionContext,
	IncomingRequestCfProperties
} from '@cloudflare/workers-types';

declare global {
	namespace App {
		interface Platform {
			env: { DB: D1Database };
			ctx: ExecutionContext;
			caches: CacheStorage;
			cf?: IncomingRequestCfProperties;
		}
	}
}

export {};
