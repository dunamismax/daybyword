# Addresses

Every place in Day by Word has one readable, stable address, the same on
the web and in the app (docs/product.md, Navigation). On the web it is a
path on daybyword.com; in the app it is a `daybyword://` link whose host and
path spell the same thing (`daybyword://plans/psalm-a-day` is
`https://daybyword.com/plans/psalm-a-day`). Universal links (P12.8) will let
daybyword.com addresses open the app directly, using these same paths.

SvelteKit routes (`web/src/routes/`) answer on the web and native Swift
routes in the app. `/api/v1` is reserved for SvelteKit catalog and compute
endpoints and later consented sync, never a direct database connection.

## The addresses

| Path | Web | App | What it shows |
|---|---|---|---|
| `/` | yes | Today | The home page on the web; Today in the app |
| `/today` | yes | yes | Today |
| `/plans` | yes | yes | Plans: recommendations, the catalog, and my plans |
| `/plans/<id>` | yes | yes | A plan's page |
| `/plans/<id>/week?start=YYYY-MM-DD` | yes | yes | A plan's week from a start date, printable (Phase 13) |
| `/plans/<id>/start` | yes | a sheet on the plan's page | Starting the plan (P8.10c) |
| `/progress` | yes | yes | Progress |
| `/settings` | yes | yes | Settings (a sheet in the app) |

On the web, Plans and each plan's page show the catalog (BUILD.md
P8.10a), and a plan's week is a checklist to print (P8.10b): the seven
days from `start` for a reader who begins the plan that day, or the
sample week without one. Today, Progress, and the app's sections are
placeholders until their items build them; every address is final.
Today on the web shows the plans this browser keeps (P8.10c), and a plan's
start page starts one there.

Addresses for the server's own use, never linked from a page a reader sees:
`/up` (the health check), `/healthz` (the deploy's check: status, the
release's commit and the database, as JSON), `/assets/…` (the site's own files), and
`/dev/components` (the component gallery, in development only).

The browser's compute endpoints, which take the journal this browser
keeps as JSON and store nothing (E52): `POST /api/v1/today` (Today's
cards) and `POST /api/v1/events` (the events an action makes).

Reserved for later phases, so nothing else takes them: the rest of
`/api/v1/…` (sync, P14; a JSON 404 until an endpoint claims an address), `/about`, `/privacy`, `/sources`, `/criteria`, and `/support` (public
pages, P16), and `/.well-known/…` (universal links and passkeys, P12.8 and
P14).

## Rules

- **Plan ids** are one to 64 lowercase ASCII letters and digits, in words
  joined by single hyphens (`gospels-at-your-pace`, `mcheyne-1842`).
  The engine's plan-id rule (docs/engine.md) is the single check: Swift's
  `PlanID` in the catalog compiler and the app, `isPlanID` on the web. An address with any other id is not
  found, and neither is one whose id is no plan in the catalog being
  served.
- **Lowercase, no trailing slash, no file extensions.** The web redirects
  an address with a trailing slash to the one without (308); the app also
  accepts a trailing slash in a link it is given.
- **Queries are for display only**, never for identity or personal data
  (AGENTS.md §5). `start` must be a date written `YYYY-MM-DD` (a civil
  date, docs/engine.md); anything else, including a date the calendar
  does not have, is ignored and the page shows its default week.
- **Never put personal data in an address**: no reading history, no
  enrollment, no account. The one exception is the secret, revocable
  calendar-feed token (P13), which is a credential and handled as one.
- **Addresses do not change.** Once an address is published, it keeps
  working. If a page moves, its old address redirects permanently to the new
  one. A plan id never changes, even when the plan gets a new version (P4.6).
- **Unknown addresses** get the site's own "Page not found" page with status
  404 on the web, and change nothing in the app.

## Where the code is

- Web: SvelteKit's `web/src/routes/` (plan ids matched in `web/src/params.ts`),
  tested against tests/fixtures/routes.json, the web's address contract, in
  `web/test/production/server.test.ts`.
- App: `AppRoute` in `apple/App/Navigation/AppRoute.swift`, tested in
  `apple/AppTests/NavigationTests.swift`. Both test files cover every row of
  the table above.
