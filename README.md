# Day by Word

**Your Bible reading companion.** *Find your plan. Read your Bible. Keep
your place.*

Day by Word helps Christians choose a Bible reading plan, know what to read
today, and keep a trustworthy record of their reading. You keep reading in
your own physical Bible, Bible app, or audio service; Day by Word supplies
the structure: a small, carefully reviewed catalog of plans, personal
scheduling, reminders, progress, and a welcoming way to pick up again after
missed days. It never shows Bible text itself.

It will be a native iPhone and iPad app and a web version at
[daybyword.com](https://daybyword.com), self-hosted by the owner. It is an
independent Christian project with no denominational affiliation, and it
does not speak for any church, ministry, or publisher.

**Status (2026-11-02):** final target is Astro + PostgreSQL/Drizzle, with
Swift retained for this project's existing iPhone/iPad app. Python is
optional tooling only when needed. The earlier Next/Expo plan was never
implemented and is withdrawn. The code still contains the original
Swift/Hummingbird/SQLite foundation; this revision changes docs only.
[BUILD.md Phase M](BUILD.md#phase-m-align-with-the-final-stack-do-first)
starts at PM.12 before feature work; [the migration brief](docs/stack-migration.md)
maps the code/data/tests and [deployment plan](docs/deploy.md) specifies
the planned host boundaries. No live deploy or app upload was performed.

## What it will do

- **Help you choose.** A few practical questions, then three suitable plans
  with honest workloads, sample weeks, and the reasons each fits, instead of
  a wall of hundreds.
- **Show today at a glance.** The next reading, set large enough to read
  from across a desk, with *Open in YouVersion*, *Copy reference*, and
  *Mark read*, also on the Lock Screen, in widgets, and in the reminder
  itself.
- **Respect the kind of plan.** *Continue at my pace*, *Work toward a finish
  date*, or *Follow the calendar*: a sequential plan moves after a holiday,
  and a calendar plan keeps its dates.
- **Make returning normal.** After missed days you get a welcome and real
  choices, each previewed before anything changes. History is never
  rewritten.
- **Be trustworthy.** Every plan has its source, coverage, workload, and
  limitations stated, with every reference verified. Historic plans and
  prayer-book lectionaries, computed from their own rules, follow after 1.0.
- **Stay private.** No ads, analytics, tracking, or AI. The app works
  offline without an account, the web keeps progress in your own browser,
  and export and deletion are there at any time. Optional sync, with
  passkeys, follows after 1.0.

## Final target (D41)

| Area | Stack and scope |
|---|---|
| Web | Astro/TypeScript, Node adapter standalone; prerender public content where useful |
| Interaction | Astro Actions and API endpoints; React islands/Tailwind/shadcn only where needed |
| Server DB | PostgreSQL + server-only Drizzle schema and reviewed SQL migrations |
| Native | Existing SwiftUI/Observation iPhone/iPad app; pinned Swift 6.4.2, iOS/iPadOS 26+ |
| Local native data | Existing ReadingData/SQLite for offline use; no direct Postgres connection |
| Rules | Swift native and TypeScript web modules, one specification/shared parity fixtures (E33) |
| Hosting | Project Compose behind host Caddy (owner-managed DNS-only Cloudflare records), private Postgres, pg_dump/off-server restore checks |
| Optional later | Better Auth in Phase 14; Swift desktop only if needed; Python utilities only for a real task |
| Excluded | Bible text, analytics/model features, mandatory Python, Next/Expo/Tauri rewrites |

Native clients call Astro APIs over HTTPS. At 1.0 personal records stay
in the app/browser; PostgreSQL holds public catalog data only. The catalog
source format, rights evidence, Morning design and eight-plan release
scope remain. The engine boundary and deterministic compiler export into
Postgres are explicit migration tasks, not completed work.

## Current architecture (legacy until Phase M)

The layout and commands below describe code that is still runnable.
Hummingbird/server SQLite will be replaced; the Swift native app remains.
See docs/stack-migration.md for the target layout.

## Current repository layout

```
AGENTS.md  BUILD.md  BUILD-HISTORY.md  README.md  LICENSE  Makefile  .swift-version  .node-version  .swift-format
catalog/                  SOURCES.md, scripture/ (book registry, versification); plans to come
Packages/ReadingEngine/   references, schedules, progress, and reminder rules (Foundation only)
Packages/ReadingData/     SQLite wrapper and catalog reader; journal/sync still open
Packages/CatalogCompiler/ the `catalog` tool that builds Catalog.sqlite
Server/                   DayByWordServer (Hummingbird 2): pages, assets in Public/, tests
web/                      the Astro web app (Node standalone), replacing Server/ through Phase M
apple/                    project.yml (XcodeGen), App/, Widgets/, AppTests/, AppUITests/, Config/
design/                   Morning tokens, mockups, image brief, and finished artwork
docs/                     decisions, product rules, release, web style, and more as they land
scripts/                  helpers behind the Makefile (simulator choice, Linux tests, archive)
.github/workflows/        CI, run by hand (D31)
```

Still to come, as BUILD.md's phases reach them: the rest of `catalog/` (plan
sources and the Hebrew, Greek, and Latin schemes) and `deploy/` (the
server's unit, Caddy site, and scripts). [The artwork inventory](design/images/README.md)
records the app icon, web exports, sharing image, and twelve plan covers.

## Current prerequisites and target additions

PM.14 adds Drizzle/pg and a local PostgreSQL for the web gate. Python,
uv, and ruff are not required unless a utility needs Python. The web
workspace (PM.13, decision E34) needs:

- **Node 26.13.0** (`.node-version`) and **npm 11.20.0**
  (`web/package.json`'s `packageManager`); `make check` refuses any other.
  Install Node from nodejs.org or a version manager that reads
  `.node-version`, then `npm install --global npm@11.20.0` if needed.
  `make web-install` runs `npm ci` from `web/package-lock.json`; Astro's
  telemetry is off through `ASTRO_TELEMETRY_DISABLED`, set by the Makefile.
- **curl**, used by `scripts/web-smoke.sh` (macOS includes it).

Retain these existing Apple tools, confirmed on the owner's Mac on
2026-10-30:

- macOS 27.2 on Apple silicon.
- **Xcode 27.2** (27B52), which ships **Swift 6.4.2**, the version pinned
  in `.swift-version`; `make check` refuses any other. Its `swift format`
  formats and lints the Swift sources. Xcode 27 calls the simulator app
  DeviceHub.
- An iOS 27 simulator runtime with at least one iPhone.
- **XcodeGen** 2.46.0: `brew install xcodegen`.
- **python3**, used by `scripts/sim-destination.sh` (any Python 3 on the
  PATH; the Command Line Tools include one).
- **Firefox** (159 here) and **geckodriver** 0.37.1 (`brew install
  geckodriver`, added 2026-11-01) for the web tour in `make check-full`
  (`make tour-web`, decision E26). Safari works too once "Allow remote
  automation" is on in Safari's Developer settings:
  `DBW_WEBDRIVER=safari make tour-web`.
- For `make test-linux`, a running container runtime: Docker Desktop, or
  Colima (`brew install colima docker`, then `colima start`). The first run
  downloads Ubuntu 24.04 and the pinned Swift toolchain (about 1 GB).
- For device builds and TestFlight only: Xcode signed in to the owner's
  Apple Developer account, and `apple/Config/Secrets.xcconfig` with the
  team ID (copy `Secrets.example.xcconfig`; see `docs/release.md`).

## Quick start

From a clean checkout:

```sh
make check       # lint, the web gate, catalog, package, server, and app tests, and the String Catalog: the gate before every commit
make check-full  # check, the web and app tours in light and dark, and Linux: at milestones and before releases
make run       # build, boot the newest iPhone simulator, install, and launch the app
make serve     # serve the site at http://localhost:8080 (/ and /up)
```

`make help` lists every target. Others worth knowing: `make test-linux`
(the packages and server on Linux), `make test-ui` (the app's UI tests),
`make check-web` (the web app's lint, types, tests, and production build,
booted and checked), `make format`, `make screenshot`, `make archive` and `make testflight`
(`docs/release.md`), and `make clean`. Set `SIM_DEVICE` to a simulator's
name or UDID to choose a device, and `PORT` to serve elsewhere.

## License

All rights reserved by the owner (BUILD.md D4; see `LICENSE`). Plans, data,
and fonts keep their own rights, recorded in `catalog/SOURCES.md`.
