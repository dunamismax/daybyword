# Addresses

Every place in Day by Word has one readable, stable address, the same on
the web and in the app (docs/product.md, Navigation). On the web it is a
path on daybyword.com; in the app it is a `daybyword://` link whose host and
path spell the same thing (`daybyword://plans/psalm-a-day` is
`https://daybyword.com/plans/psalm-a-day`). Universal links (P12.8) will let
daybyword.com addresses open the app directly, using these same paths.

## The addresses

| Path | Web | App | What it shows |
|---|---|---|---|
| `/` | yes | Today | The home page on the web; Today in the app |
| `/today` | yes | yes | Today |
| `/plans` | yes | yes | Plans: recommendations, the catalog, and my plans |
| `/plans/<id>` | yes | yes | A plan's page |
| `/plans/<id>/week?start=YYYY-MM-DD` | yes | yes | A plan's week from a start date, printable (Phase 13) |
| `/progress` | yes | yes | Progress |
| `/settings` | yes | yes | Settings (a sheet in the app) |

Today, Plans, Progress, and Settings are placeholders until their phases
build them, but their addresses are final.

Addresses for the server's own use, never linked from a page a reader sees:
`/up` (the health check), `/assets/…` (the site's own files), and
`/dev/components` (the component gallery, in development only).

Reserved for later phases, so nothing else takes them: `/api/v1/…` (sync,
P14), `/about`, `/privacy`, `/sources`, `/criteria`, and `/support` (public
pages, P16), and `/.well-known/…` (universal links and passkeys, P12.8 and
P14).

## Rules

- **Plan ids** are one to 64 lowercase ASCII letters and digits, in words
  joined by single hyphens (`gospels-at-your-pace`, `mcheyne-1842`).
  `ReadingEngine`'s `PlanID` is the single check, used by the catalog
  compiler, the server, and the app. An address with any other id is not
  found.
- **Lowercase, no trailing slash, no file extensions.** The app also accepts
  a trailing slash in a link it is given.
- **Queries are for display only**, never for identity or personal data
  (AGENTS.md §5). `start` must look like `YYYY-MM-DD`; anything else is
  ignored and the page shows its default week. (Checking that the date
  exists waits for `CivilDate`, P5.3.)
- **Never put personal data in an address**: no reading history, no
  enrollment, no account. The one exception is the secret, revocable
  calendar-feed token (P13), which is a credential and handled as one.
- **Addresses do not change.** Once an address is published, it keeps
  working. If a page moves, its old address redirects permanently to the new
  one. A plan id never changes, even when the plan gets a new version (P4.6).
- **Unknown addresses** get the site's own "Page not found" page with status
  404 on the web, and change nothing in the app.

## Where the code is

- Web: the routes in `Server/Sources/DayByWordWeb/Application+build.swift`,
  tested in `Server/Tests/DayByWordWebTests/ServerTests.swift`.
- App: `AppRoute` in `apple/App/Navigation/AppRoute.swift`, tested in
  `apple/AppTests/NavigationTests.swift`. Both test files cover every row of
  the table above.
