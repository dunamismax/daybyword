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

**Status (2026-11-01):** the foundation is being built. The app and the
site have their three sections, Settings, and shared addresses, with
placeholders where plans will go; the first build is on TestFlight for the
owner; the shared packages pass their tests on macOS and Linux; and
daybyword.com is not serving yet.
[BUILD.md](BUILD.md) is the plan and records its current state, finished
phases move to [BUILD-HISTORY.md](BUILD-HISTORY.md), and
[AGENTS.md](AGENTS.md) governs how the work is done.

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
  and Easter readings stay at Easter.
- **Make returning normal.** After missed days you get a welcome and real
  choices, each previewed before anything changes. History is never
  rewritten.
- **Be trustworthy.** Every plan has its exact edition, source, coverage,
  limitations, and permissions stated, and historic prayer-book lectionaries
  are computed from their own rules.
- **Stay private.** No ads, analytics, tracking, or AI. The app works
  offline without an account; backup and sync are optional, with passkeys,
  and with export and deletion at any time.

## The plan at a glance

| | |
|---|---|
| App | iPhone and iPad in SwiftUI, iOS 26 and later. Android readers use the installable web app until a native Android decision after 1.0 |
| Web | daybyword.com, served by a Swift server on Hummingbird 2 with SQLite: public plan pages, the web app, and the sync API, for current browsers |
| Engine | One Swift package, `ReadingEngine`, shared by the app, its widgets, the server, and the catalog compiler |
| Plans | Compiled from plain-text sources in `catalog/`, with every reference verified, every coverage claim computed, and every source's rights recorded |
| Hosting | The owner's Ubuntu server behind Caddy, built on the server from `main` at each deploy |
| Path | Foundation, then first light (Today and three plans), then version 1.0 with twelve plans, a short beta, and the US App Store |

## Repository layout

```
AGENTS.md  BUILD.md  BUILD-HISTORY.md  README.md  LICENSE  Makefile  .swift-version  .swift-format
Packages/ReadingEngine/   references, schedules, progress, and reminder rules (Foundation only)
Packages/ReadingData/     the SQLite wrapper, catalog reader, journal, and sync client
Packages/CatalogCompiler/ the `catalog` tool that builds Catalog.sqlite
Server/                   DayByWordServer (Hummingbird 2): pages, assets in Public/, tests
apple/                    project.yml (XcodeGen), App/, Widgets/, AppTests/, AppUITests/, Config/
design/                   Morning tokens, mockups, image brief, and finished artwork
docs/                     decisions, product rules, release, web style, and more as they land
scripts/                  helpers behind the Makefile (simulator choice, Linux tests, archive)
.github/workflows/        CI, run by hand (D31)
```

Still to come, as BUILD.md's phases reach them: `catalog/` (plan sources,
scripture data, and `SOURCES.md`) and `deploy/` (the server's unit, Caddy
site, and scripts). [The artwork inventory](design/images/README.md)
records the app icon, web exports, sharing image, and twelve plan covers.

## Prerequisites

Confirmed on the owner's Mac on 2026-10-30:

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
  geckodriver`, added 2026-11-01) for the web tour in `make check`
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
make check     # lint, catalog, package, server, and app tests, the String Catalog, and the web tour: the gate before every commit
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
