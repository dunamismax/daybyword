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

**Status (2026-10-30):** planning is complete and every product decision is
recorded, but there is no code yet, and daybyword.com is not serving yet.
[BUILD.md](BUILD.md) is the plan and records its current state;
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

The repository holds only these documents today. Phase 1 of BUILD.md
creates the rest:

```
AGENTS.md  BUILD.md  README.md  LICENSE  Makefile  .swift-version
catalog/                  plan sources, rule tables, scripture data, SOURCES.md
Packages/ReadingEngine/   references, schedules, progress, reminder rules
Packages/ReadingData/     SQLite, catalog reader, journal, sync client
Packages/CatalogCompiler/ the `catalog` tool that builds Catalog.sqlite
Server/                   DayByWordServer (Hummingbird 2)
apple/                    the Xcode project (XcodeGen), app, widgets, and tests
design/  docs/  deploy/  scripts/
```

## Prerequisites

These were confirmed on the owner's Mac on 2026-10-30 (BUILD.md Research
finding 13), and BUILD.md P1.13 brings this section up to date as the
toolchain lands:

- macOS 27.2 on Apple silicon
- Xcode 27.2 with Swift 6.4.2, and iOS 27 simulators
- XcodeGen 2.46.0 (`brew install xcodegen`)

## Quick start

There is nothing to run yet. Once Phase 1 lands, this section will show how
to go from a clean checkout to a running app (`make run`) and a local server
(`make serve`), with `make check` as the single gate before every commit.

## License

All rights reserved by the owner (BUILD.md D4); the `LICENSE` file arrives
with P1.2. Plans, data, and fonts keep their own rights, recorded in
`catalog/SOURCES.md`.
