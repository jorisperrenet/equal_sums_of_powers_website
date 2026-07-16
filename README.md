# Equal Sums of Like Powers

AI-powered website that functions as a record page.

A public, machine-verified archive built with SvelteKit, Tailwind CSS, Cloudflare Workers, and D1.

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

## Deploy to Cloudflare

Create the free D1 database and replace the placeholder `database_id` in `wrangler.jsonc`:

```sh
npx wrangler login
npx wrangler d1 create manifold
npm run db:migrate:remote
npm run deploy
```

Valid public submissions are recomputed with exact `BigInt` arithmetic, checked for primitivity, deduplicated, and inserted automatically.

## Quality checks

```sh
npm run check
npm test
npm run lint
```
