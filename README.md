# Equal Sums of Like Powers

A public, machine-verified archive built with SvelteKit, Tailwind CSS, Cloudflare Workers,
and D1. The production site is available at <https://powersums.jorisperrenet.com>.

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

## Database migrations

To propose an edit to the database, create a new migration in `migrations/` and include it in your
pull request. Do not edit a migration that has already been applied. The migration will be reviewed
and applied after the pull request is approved.

Create and verify the migration locally with:

```sh
npx wrangler d1 migrations create manifold descriptive_name
npm run db:migrate:local
npm run check:database
```

Valid public submissions are recomputed with exact `BigInt` arithmetic, checked for primitivity, deduplicated, and inserted automatically.

## Quality checks

```sh
npm run check
npm test
npm run lint
```
