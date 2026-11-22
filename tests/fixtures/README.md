# Shared fixtures

Inputs, and the outputs Day by Word's Swift engine gives for them, which
the TypeScript web module must give too (docs/decisions.md E33,
docs/engine.md); the Swift tests named below check them on every
`make check`, so a fixture never drifts from the code that made it. The
engine fixtures (`references` through `recommendations`) are also checked by
the TypeScript domain module in Node (`web/test/domain/`, every `make check`)
and in headless Firefox (`make test-domain-browser`, in `make check-full`).

| File | What it pins | Checked by |
|---|---|---|
| `references.json` | Plan-file reading text: its shortest writing, passages, verses, WEB words, minutes, and display in each naming convention; or the first error's kind and message | `ReadingEngineTests/FixtureTests.swift` |
| `coverage.json` | Readings' verses, unique verses, repeats, whole and partial chapters, verses by book | same |
| `workload.json`, `plan-workload.json` | Minutes from words; a plan's lightest, middle, and heaviest readings | same |
| `scripture.json` | Every registered book's chapters, verses, words, and names; each canon's books, orders, and totals | same |
| `plan-ids.json` | Which text is a plan id | same |
| `scripture-files.json` | Small invented registry, versification and word-count files, and what reading each gives or its first problem (PM.15) | same |
| `civil-dates.json` | A date's weekday, month length, day of the year and day number; the date some days later; the days to another date; or the error's kind and message (P5.3) | same |
| `event-ids.json` | Which text is a UUIDv7 event id and the milliseconds it was made at; the id made from a millisecond count and ten random bytes (P5.4) | same |
| `journal.json` | The journal's fold: events in their wire form against invented plans, giving the inert events and why, what is undone, and each enrollment's slots, start, end, paused days and arrangement on a date; or why the journal is refused (P5.2, P5.4) | same, and `JournalTests.swift` (any arrival order) |
| `today.json` | Today for each enrollment on a date: its status, the readings to read, those read today, the next reading; a pace enrollment's projected finish; a finish-date enrollment's schedule, share and outstanding readings; a calendar enrollment's appointment, the readings a short month does not appoint, and the missed count (P5.5 to P5.7) | same |
| `returning.json` | Whether each enrollment is offered the welcome after a gap, the choices that apply with the finish and readings remaining each would set, and each one's preview: today's answer were it recorded (P5.8) | same |
| `changing.json` | A change the reader is considering: the candidate event the engine makes (with a new basis where the rules call for one), why it would be inert, and today's answer before and after (P5.10) | same |
| `progress.json` | Each enrollment's readings by state, the seven dates ending today (read, and a reading day), coverage across all enrollments with each verse once (verses, passages, whole and partial chapters, books explored), and the streak (P5.11) | same |
| `celebrations.json` | Quiet celebrations on a date: each enrollment's return after a gap, the books it finished (its own coverage) and its finishing, in the order started, then whether the week's reading days were each read (P11.2) | same |
| `reminders.json` | From the journal, the local date and wall-clock time now, quiet hours, the most a day, snoozes and a window: the local dates and times reminders should fire at, earliest first, each with the reading it is about (P5.12) | same; the wall-clock edge in `CivilDateTests.swift` |
| `ahead.json` | The days ahead: for each enrollment, the dates from today on, each with whether it is a reading day and the readings expected on it; a sample week is the same list for a plan just enrolled in (P8.2a) | same, and `theDaysAheadAreWhatTodayWillShow`, which marks each day's readings read and asks Today |
| `bible-links.json` | Where a reading opens in YouVersion and on Bible.com: the address for a reading and a translation, whether it holds the whole reading or opens at its first chapter, and each translation's abbreviation and name (P8.5, docs/destinations.md) | same, and `everyTranslationIsInTheBibleLinksFixture` |
| `recommendations.json` | Choosing a plan: invented candidates in the catalog's order and a reader's answers (a goal, a time, days a week; any may be "not sure") give at most three plans, each with the goal it answers, its typical minutes, whether the time and days fit, the readings a week and the weeks (P9.2) | same |
| `plan-files.json` | Invented plan files and what the compiler reads and computes, or its first problem | `CatalogCompilerTests/FixtureTests.swift` |
| `catalog-export.json` | An invented release catalog as `catalog export` writes it (PM.14), whose checksum the PostgreSQL import recomputes; not in the cases format | `CatalogCompilerTests/CatalogExportTests.swift`, `web/test/` |
| `routes.json` | The web's address contract (docs/urls.md): each address's status, content type, cache policy, redirect, title, heading, and current section; the security headers (written by hand since PM.20) | `web/test/production/server.test.ts` |
| `settings.json` | The settings kept on the reader's device, on the web and in the app (written by hand) | `web/test/strings.test.ts` and `apple/AppTests/SettingsFixtureTests.swift` |

## Format

Each file is JSON: `fixture` (its name), `version`, `about`, and `cases`, each
an `input` and the `output` the code gives. An absent field means "none"
(for example no `words` when a book has no word counts). Messages are the
compiler's and engine's English wording for plan authors; a runtime that
only needs to tell readers something may match on the error kind instead.

- Numbers are JSON numbers, read as IEEE doubles. Halves round away from
  zero (Swift's `rounded()`, which `Math.round` matches for the positive
  values here).
- Chapter and verse places are written `chapter:verse`; readings use the
  plan-file format (docs/decisions.md E30).
- No Scripture text ever appears here (D13), and plan files are invented,
  never a real plan's schedule (AGENTS.md §6).

**Scheduling fixtures** (`journal` and those that follow it, P5.2) also have
`plans`: invented plan versions (id, version, schedule, behaviors, reading
days a week, and assignments with readings in the plan-file format) that
the cases enroll in. Each case has a `name` saying what it shows, and its
input carries the events in their wire form (docs/engine.md, "The
journal") in the order they arrived, the dates asked about, and later
`today`. Event ids are written so that their order is plain to read
(`0195a7c2-0002-…` follows `0195a7c2-0001-…`).

## Changing a fixture

A change in meaning bumps the file's `version` and says why in the commit. To
rewrite the outputs from the Swift code, run the owning tests with
`DBW_RECORD_FIXTURES=1`, for example

~~~sh
DBW_RECORD_FIXTURES=1 swift test --package-path Packages/ReadingEngine --filter FixtureTests
~~~

then review the diff line by line: recording accepts whatever the code does
now, so an unexplained change is a bug, not a new expectation. Add inputs by
editing `cases` (an input with no `output` yet) and recording.
