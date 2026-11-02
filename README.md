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

**Status (2026-11-02):** the existing Swift foundation has app/web shells,
Scripture references and catalog tooling; scheduling and plan content are
still to come. The owner has selected a unified stack: Next.js/React,
Tailwind/shadcn, PostgreSQL/Drizzle, Docker Compose and Expo.
**Implementation has not started.** [BUILD.md Phase M](BUILD.md#phase-m-unified-stack-rewrite-do-first)
comes before all feature work, and [the migration brief](docs/stack-migration.md)
maps the inspected code, data and tests to the target architecture.
[AGENTS.md](AGENTS.md) governs the work; completed phases remain in
[BUILD-HISTORY.md](BUILD-HISTORY.md). The prior handoff reports a
TestFlight build and no deployment; this documentation review did not
inspect either service.

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

## The target stack (D40)

| | |
|---|---|
| App | Expo / React Native for iPhone and iPad, iOS 26+; local builds, native adapters for Apple integration as needed |
| Web | Next.js App Router + React + TypeScript, Tailwind CSS and shadcn/ui styled with Morning tokens; standalone Node output |
| Engine | One pure TypeScript package shared by Next, Expo, browser offline code and the catalog compiler |
| Server data | PostgreSQL through Drizzle TypeScript schema and committed SQL migrations; public catalog only at 1.0 |
| Local data | Expo SQLite and browser IndexedDB; no account required, no client connection to server Postgres |
| Plans | Existing plain-text catalog sources and rights evidence; deterministic compiler artifact imported into Postgres and bundled on mobile |
| Hosting | Project Docker Compose on ubuntu-vm, loopback web port behind host Caddy, Cloudflare TLS, nightly encrypted off-server pg_dump backups |
| Later, only when needed | Better Auth for optional accounts after 1.0; Stripe for billing; Tauri for desktop; Expo Android after D6 |
| Excluded | Bible text, analytics and AI features, including any model SDK (D13/D23) |

## Target architecture

~~~text
catalog/ + SOURCES.md ── TypeScript compiler ── versioned release artifact
                                                │              │
                                    Drizzle → PostgreSQL     bundled/cached
                                                │              │
Caddy/Cloudflare → Compose Next.js standalone ← HTTPS → Expo / browser
                  public SSR + catalog API       local SQLite / IndexedDB
                        │                              │
                        └──── same TypeScript engine ──┘
~~~

At 1.0 personal records remain in the device/browser; local computations
use the shared engine. Future consented sync and Better Auth run through
Next APIs and server-only Drizzle. PostgreSQL is never reachable from a
client. See [the migration brief](docs/stack-migration.md) for workspace
paths, data contracts and native integration boundaries, and
[deployment planning](docs/deploy.md) for Compose/Caddy paths, ports,
database naming, TLS, backups and rollback. These are planned conventions,
not claims that infrastructure has been provisioned.

## Current repository layout (legacy, until Phase M)

```
AGENTS.md  BUILD.md  BUILD-HISTORY.md  README.md  LICENSE  Makefile  .swift-version  .swift-format
catalog/                  SOURCES.md, scripture/ (book registry, versification); plans to come
Packages/ReadingEngine/   references, plan types, coverage and workload (scheduling still open)
Packages/ReadingData/     SQLite wrapper and catalog reader (journal/sync still open)
Packages/CatalogCompiler/ the `catalog` tool that builds Catalog.sqlite
Server/                   DayByWordServer (Hummingbird 2): pages, assets in Public/, tests
apple/                    project.yml (XcodeGen), App/, Widgets/, AppTests/, AppUITests/, Config/
design/                   Morning tokens, mockups, image brief, and finished artwork
docs/                     decisions, product rules, release, web style, and more as they land
scripts/                  helpers behind the Makefile (simulator choice, Linux tests, archive)
.github/workflows/        CI, run by hand (D31)
```

Numeric scripture data is present, including WEB word counts. Plan files
are still absent; Hebrew/Greek/Latin schemes wait until after 1.0.
Phase M creates the new workspace and Compose deployment files; the layout
above documents the inspected legacy source, not the target structure.
[The artwork inventory](design/images/README.md)
records the app icon, web exports, sharing image, and twelve plan covers.

## Current prerequisites (legacy checks)

These run the code still checked in. PM.2 will pin and document supported
Node/npm, Next/React, Expo/React Native, Postgres and test-tool versions;
Docker Compose and local Apple build tools are required for the target.
No hosted build, auth or model account is needed for migration.

Legacy tools confirmed on the owner's Mac on 2026-10-30:

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

## Current quick start (legacy, still runnable)

From a clean checkout:

```sh
make check       # lint, catalog, package, server, and app tests, and the String Catalog: the gate before every commit
make check-full  # check, the web and app tours in light and dark, and Linux: at milestones and before releases
make run       # build, boot the newest iPhone simulator, install, and launch the app
make serve     # serve the site at http://localhost:8080 (/ and /up)
```

`make help` lists every target. Others worth knowing: `make test-linux`
(the packages and server on Linux), `make test-ui` (the app's UI tests),
`make format`, `make screenshot`, `make archive` and `make testflight`
(`docs/release.md`), and `make clean`. Set `SIM_DEVICE` to a simulator's
name or UDID to choose a device, and `PORT` to serve elsewhere.

## License

All rights reserved by the owner (BUILD.md D4; see `LICENSE`). Plans, data,
and fonts keep their own rights, recorded in `catalog/SOURCES.md`.
