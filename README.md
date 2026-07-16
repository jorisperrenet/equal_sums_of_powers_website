# Equal Sums of Like Powers

A public, machine-verified archive built with SvelteKit, Tailwind CSS, Cloudflare Workers,
and D1. The production site is available at <https://sums.jorisperrenet.com>.

## Local development

```sh
npm install
npm run db:migrate:local
npm run dev
```

The single migration creates the normalized schema and imports the verified reference tables.

Inspect the local database with:

```sh
npx wrangler d1 execute manifold --local --command "SELECT * FROM submissions LIMIT 20"
```

Local development uses a database under `.wrangler/`; it never connects to or changes the
production database.

## Contributing

Create a branch, make and test the change locally, and open a pull request.

## Production deployment

The `main` branch deploys to the existing `manifold` Cloudflare Worker through Cloudflare's GitHub
integration. That Worker is bound to the shared production D1 database as `DB`, using the binding
declared in `wrangler.jsonc`.

The production application does not need to poll or copy the database. Every page request queries
the shared remote D1 database directly through `env.DB`, and every accepted public submission is
written to it immediately. Production data lives in D1 rather than in the Git repository.

Deploying a new version of the Worker updates the application code and static assets only. It does
not recreate, replace, or clear D1, so existing public submissions remain available after every
deployment.

To deploy manually:

```sh
npm run deploy
```

## Database migrations

Create and verify schema migrations locally first:

```sh
npx wrangler d1 migrations create manifold descriptive_name
npm run db:migrate:local
npm run check:database
```

Use backward-compatible migrations so the currently deployed Worker continues to work. Apply the
migration to production before merging code that depends on the new schema:

```sh
npm run db:migrate:remote
npm run check:database -- --remote
```

Valid public submissions are recomputed with exact `BigInt` arithmetic, checked for primitivity, deduplicated, and inserted automatically.

## Quality checks

```sh
npm run check
npm test
npm run lint
```
