# Shared fixtures

Inputs, and the outputs Day by Word's Swift code gives for them, captured at
PM.12 (BUILD.md) before the Astro/PostgreSQL migration replaces anything. The
TypeScript web module and the Astro site must give the same outputs
(docs/decisions.md E33); the Swift tests named below check them on every
`make check`, so a fixture never drifts from the code that made it.

| File | What it pins | Checked by |
|---|---|---|
| `references.json` | Plan-file reading text: its shortest writing, passages, verses, WEB words, minutes, and display in each naming convention; or the first error's kind and message | `ReadingEngineTests/FixtureTests.swift` |
| `coverage.json` | Readings' verses, unique verses, repeats, whole and partial chapters, verses by book | same |
| `workload.json`, `plan-workload.json` | Minutes from words; a plan's lightest, middle, and heaviest readings | same |
| `scripture.json` | Every registered book's chapters, verses, words, and names; each canon's books, orders, and totals | same |
| `plan-ids.json` | Which text is a plan id | same |
| `plan-files.json` | Invented plan files and what the compiler reads and computes, or its first problem | `CatalogCompilerTests/FixtureTests.swift` |
| `catalog-export.json` | An invented release catalog as `catalog export` writes it (PM.14), whose checksum the PostgreSQL import recomputes; not in the cases format | `CatalogCompilerTests/CatalogExportTests.swift`, `web/test/` |
| `routes.json` | Each web address's status, content type, cache policy, title, heading, and current section; the security headers | `DayByWordWebTests/FixtureTests.swift` |
| `strings.json` | The web's interface text by key | same |
| `settings.json` | The settings kept on the reader's device, on the web and in the app (written by hand) | the server tests and `apple/AppTests/SettingsFixtureTests.swift` |

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
