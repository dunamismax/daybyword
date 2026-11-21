# Day by Word

**Your Bible reading companion.** *Find your plan. Read your Bible. Keep
your place.*

Day by Word helps Christians choose a Bible reading plan, know what to read
today, and keep a trustworthy record of their reading. You keep reading in
your own paper Bible, Bible app, or audio service. Day by Word supplies the
structure: a small, carefully reviewed catalog of plans, personal
scheduling, reminders, progress, and a welcoming way to pick up again after
missed days. It never shows Bible text itself.

It is a native iPhone and iPad app and a web version at
[daybyword.com](https://daybyword.com), self-hosted by the owner. It is an
independent Christian project with no denominational affiliation, and it
does not speak for any church, ministry, or publisher.

| | |
|---|---|
| **Website** | [daybyword.com](https://daybyword.com), live and marked "in development" |
| **Plan** | [BUILD.md](BUILD.md): every step to version 1.0, with its current state |
| **Source** | [GitHub](https://github.com/dunamismax/daybyword) · [Codeberg](https://codeberg.org/dunamismax/daybyword) |
| **Support** | support@daybyword.com |

## Status

**In development; nothing is ready to read with yet (2026-11-21).**

- **daybyword.com is live** in development: SvelteKit serves every page
  under a strict security policy, hidden from search engines. Plans lists
  the catalog's first three plans, each with its own page (what it is,
  its workload, a sample week, what it covers). A plan cannot be started
  there yet.
- **The iPhone and iPad app** builds and runs in the simulator with the same
  sections. It is not yet on the App Store or in a beta.
- **The reading rules are built** ([docs/engine.md](docs/engine.md), version 1),
  and the three plans are Day by Word's own ([docs/plans.md](docs/plans.md)).
- **Next:** **first light** (Phase 8): starting a plan, Today, marking,
  reminders, and the return after missed days, on TestFlight and at
  daybyword.com.

## What it will do

- **Help you choose.** A few practical questions, then two or three
  suitable plans with honest workloads, sample weeks, and the reasons each
  fits, instead of a wall of hundreds.
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
- **Be trustworthy.** Every plan states its source, coverage, workload, and
  limitations, and every reference is checked by the compiler.
- **Stay private.** The app works offline without an account, the web keeps
  your progress in your own browser, and export and deletion are there at
  any time.

## What it is not

- **Not a Bible.** It never shows Scripture text, only references, and it
  opens your own Bible app or leaves you with your paper one.
- **Not a scorecard.** No badges, points, leaderboards, countdowns, or
  "you're falling behind" messages. A streak is optional, off by default,
  and never in charge. A missed day is simply a day.
- **Not watching you.** No ads, analytics, tracking, or data sales, ever.
- **No AI features.** No generative models, chat, or AI recommendations.
- **Not a church or a publisher.** It speaks for no tradition, describes
  each one in its own terms, and takes no side on questions Christians
  dispute.

## The road to 1.0

| Milestone | What it delivers |
|---|---|
| M0 Stack alignment | The web and server on SvelteKit and PostgreSQL, the native app kept as it is (done) |
| M1 Foundation | References, the catalog compiler, the reading engine, and daybyword.com deployed in development |
| M2 First light | Three plans, Today, marking, reminders, and the return flow, on TestFlight and the web |
| M3 Version 1.0 | Choosing a plan, the eight-plan launch catalog, progress, widgets, print, the installable web app, legal pages, a beta, and launch |
| After 1.0 | Church calendars and historic plans, optional accounts and sync, more Bible apps, groups, and more ([docs/roadmap.md](docs/roadmap.md)) |

## Technology

| Layer | Choice | In the checkout today |
|---|---|---|
| Web | SvelteKit 3, Svelte 5, TypeScript, Tailwind CSS 4 on `@sveltejs/adapter-node` | Every page server-rendered, no client runtime yet (E38) |
| Server data | PostgreSQL 18 with Drizzle ORM and reviewed SQL migrations | Public catalog data only; no reader records on the server at 1.0 |
| Native | SwiftUI and Observation on Swift 6.4.2, iOS and iPadOS 26 or later, WidgetKit | The app shell and a placeholder widget |
| Local native data | SQLite through `ReadingData`, bundled read-only catalog | Catalog reader; the reading journal is still to come |
| Reading rules | One specification ([docs/engine.md](docs/engine.md)), a Swift and a TypeScript runtime held to the same JSON cases | References, verse sets, workload, and civil dates in both; scheduling is specified and being built (Phase 5) |
| Catalog | Plain-text plan sources, compiled and checked by a Swift tool that refuses unverified references and uncleared sources | No plans yet |
| Hosting | Docker Compose behind the host's Caddy, nightly `pg_dump` and restore checks | Live; the off-server backup copy is still open (P7.3) |

The apps call the server only over HTTPS; nothing outside the server
connects to PostgreSQL. The full stack decision is D42 in BUILD.md, and
the engineering reasons are in [docs/decisions.md](docs/decisions.md).

## Repository layout

```
AGENTS.md  BUILD.md  BUILD-HISTORY.md  README.md  LICENSE  Makefile
apple/                    the iPhone and iPad app: project.yml (XcodeGen), App/, Widgets/, tests, Config/
web/                      daybyword.com: SvelteKit routes, components, the TypeScript engine, Drizzle schema and migrations
Packages/ReadingEngine/   the Swift engine: references, verse sets, workload, and the scheduling rules to come
Packages/ReadingData/     SQLite wrapper and catalog reader for the app
Packages/CatalogCompiler/ the `catalog` tool that builds and exports the catalog
catalog/                  plan sources, scripture data (book registry, versification), and SOURCES.md (rights)
tests/fixtures/           the shared cases both engines must pass, and the web's address contract
deploy/                   Dockerfile, Compose project, Caddy site file, systemd timers, deploy and backup scripts
design/                   Morning's design tokens, mockups, image prompts, and the owner's artwork
docs/                     product rules, design, engine, catalog, editorial, deployment, release, decisions
scripts/                  helpers behind the Makefile
.github/workflows/        CI, run by hand (D31)
```

## Working on it

| To work on | Start here |
|---|---|
| What every screen must and must not do | [docs/product.md](docs/product.md), [docs/design.md](docs/design.md) |
| Reading rules | [docs/engine.md](docs/engine.md), then [tests/fixtures/](tests/fixtures/) |
| The engine in Swift and in TypeScript | [Packages/ReadingEngine/](Packages/ReadingEngine/), [web/src/lib/domain/](web/src/lib/domain/) |
| Plans, sources, and rights | [docs/catalog-format.md](docs/catalog-format.md), [docs/plans.md](docs/plans.md), [docs/editorial.md](docs/editorial.md), [catalog/SOURCES.md](catalog/SOURCES.md) |
| Web pages and the app API | [web/src/routes/](web/src/routes/), [docs/urls.md](docs/urls.md), [docs/web.md](docs/web.md) |
| The server database | [web/src/lib/server/db/](web/src/lib/server/db/), [web/drizzle/](web/drizzle/) |
| The native app | [apple/](apple/), [docs/release.md](docs/release.md) |
| The live host | [docs/deploy.md](docs/deploy.md), [deploy/](deploy/) |

### Quick start

```sh
make check       # the gate before every commit: lint, web, catalog, packages, app tests, String Catalog
make serve-web   # the SvelteKit production build at http://localhost:8080
make run         # build, boot the newest iPhone simulator, install, and launch the app
make check-full  # check, the engine cases in Firefox, both tours in light and dark, and Linux
```

`make help` lists every target. Others worth knowing: `make check-web` (the
web gate alone), `make test-db` (migrations, catalog import, and roles on a
throwaway PostgreSQL 18), `make tour-web` and `make tour-app`, `make
test-linux`, `make rehearse-deploy`, `make format`, and `make archive` and
`make testflight` ([docs/release.md](docs/release.md)). Set `SIM_DEVICE` to
choose a simulator and `PORT` to serve elsewhere.

### Prerequisites

`make check` refuses any Swift, Node, or npm version other than the pinned
one. Confirmed on the owner's Mac (macOS 27.2, Apple silicon):

| Tool | Version | Needed for |
|---|---|---|
| Xcode | 27.2 (27B52), with Swift 6.4.2 (`.swift-version`) and an iOS 27 simulator with an iPhone | everything Swift; its `swift format` formats and lints. Xcode 27 calls the simulator app DeviceHub |
| XcodeGen | 2.46.0 (`brew install xcodegen`) | generating the Xcode project |
| Node | 26.13.0 (`.node-version`) | the web workspace; install from nodejs.org or a version manager that reads `.node-version` |
| npm | 11.20.0 (`packageManager` in `web/package.json`) | `make web-install` runs `npm ci`; `npm install --global npm@11.20.0` if needed |
| PostgreSQL | 18, server binaries on the PATH (`brew install postgresql@18`) | `make test-db`, `make serve-web`, the production tests and the web tour, each of which starts and deletes its own throwaway cluster; `scripts/with-postgres.sh` finds Homebrew's 18 when another major comes first |
| python3 | any Python 3 (the Command Line Tools include one) | `scripts/sim-destination.sh` |
| curl | any | `scripts/web-smoke.sh` |
| Firefox and geckodriver | Firefox 159, geckodriver 0.37.1 (`brew install geckodriver`) | `make tour-web` and `make test-domain-browser` in `check-full`; Safari works with "Allow remote automation" on (`DBW_WEBDRIVER=safari make tour-web`) |
| Docker with Compose v2 | Docker Desktop, or Colima (`brew install colima docker docker-compose`, then `colima start`) | `make test-linux` and `make rehearse-deploy`; the first run downloads Ubuntu 24.04 and the pinned Swift toolchain (about 1 GB) |

For device builds and TestFlight only: Xcode signed in to the owner's Apple
Developer account, and `apple/Config/Secrets.xcconfig` with the team ID
(copy `Secrets.example.xcconfig`; see [docs/release.md](docs/release.md)).
Python, uv, and ruff are not needed unless a utility comes to need Python.
SvelteKit, Vite, and Tailwind send no telemetry.

## How it is built

The owner decides the product. AI coding agents do the engineering, the
catalog research, and the deployment, working under [AGENTS.md](AGENTS.md)
and ticking off [BUILD.md](BUILD.md) as they go. That is how the code is
written, not a feature: Day by Word itself has no AI features (D23).

## License

All rights reserved by the owner (BUILD.md D4; see [LICENSE](LICENSE)).
The source is published to be read, not reused. Plans, data, and fonts keep
their own rights, recorded in [catalog/SOURCES.md](catalog/SOURCES.md).
