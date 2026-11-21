# Shared fixtures

Inputs, and the outputs Day by Word's Swift engine gives for them, which
the TypeScript web module must give too (docs/decisions.md E33,
docs/engine.md); the Swift tests named below check them on every
`make check`, so a fixture never drifts from the code that made it. The
engine fixtures (`references` through `civil-dates`) are also checked by
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
