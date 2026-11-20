# The reading engine

Specification version: **0**

Day by Word's reading logic has one specification, this file, and two
runtimes held to it: Swift's `ReadingEngine` (`Packages/ReadingEngine`)
for the app, its extensions and the catalog compiler, and the TypeScript
domain module (`web/src/lib/domain/`) for the web's server and browser
(docs/decisions.md E33). Both answer the same shared cases in
[tests/fixtures/](../tests/fixtures/README.md), and a rule is not done until
both do.

Version 0 covers what both runtimes already do: identifiers, scripture
data, references, verse sets, word counts and workload (BUILD.md PM.15).
Plans, enrollments, the journal, the three behaviors, progress and
reminders are written by P5.1, which makes this version 1; until then
neither runtime has them. Both runtimes state the version they implement
(`ReadingEngine.specificationVersion`, `specificationVersion`), and a web
test checks that the two and this line agree.

## The boundary

- **Where rules live.** Only in the two runtimes. Svelte components, load
  functions, form actions, `/api/v1` endpoints, SQL, Swift views and
  scripts call them and never restate a rule. There is no Swift service
  behind the web, and no third runtime (no Python engine).
- **Purity.** The TypeScript module imports nothing but itself: no DOM,
  no Node APIs, no Svelte or SvelteKit, no database, so the server and
  the browser run the same code. The web lint refuses other imports in
  `src/lib/domain/`. Callers load the scripture files and pass their text
  in, as Swift's callers pass `Data` and `String`.
- **Data.** Both runtimes read the repository's files: `books.json`, the
  English versification and the WEB word counts in `catalog/scripture/`
  (docs/scripture.md). The server's PostgreSQL catalog carries the first
  two as scripture resources and each assignment's words as numbers
  (docs/catalog-format.md, "The export"); the word-count file itself
  stays a compiler and test input. No Scripture text is in any of them
  (D13).
- **Parity.** `make check` runs every shared case through Swift
  (`FixtureTests`) and through the TypeScript module in Node
  (`web/test/domain/`). `make test-domain-browser` runs the same cases in
  a real browser (Firefox, headless, through geckodriver), and
  `make check-full` includes it. When the runtimes disagree, the
  specification decides; record the difference and fix the runtime that is
  wrong, never the fixture to match it.
- **Cases.** A new rule gets its cases first (AGENTS.md §7): inputs in
  `tests/fixtures/`, outputs recorded from the runtime that implements it
  and checked by hand, then the other runtime made to pass. A change in
  meaning bumps the fixture's `version`.

## Identifiers

- **Book ids** are USFM 3.0: exactly three bytes, capital ASCII letters
  and digits, at least one a letter (`GEN`, `1SA`, `S3Y`; never `gen`,
  `123`, `ÉST`). Whether a book is registered is the registry's question.
- **Plan ids** are 1 to 64 lowercase ASCII letters and digits in words
  joined by single hyphens (`gospels-at-your-pace`, `1662`; never
  `Psalm-a-day`, `-psalm`, `psalm--a-day`). They are the same in the
  catalog, in addresses (docs/urls.md) and in every runtime.
- **Assignment ids** are positive whole numbers given by the plan file,
  never reused (docs/catalog-format.md). An enrollment records the plan id
  and version it follows (P5.4).

## The wire

What crosses between runtimes, the catalog and future `/api/v1` calls.

- **JSON numbers** are IEEE doubles. Counts (verses, words, chapters,
  minutes, ids, positions) are whole numbers within JavaScript's safe
  integers; a runtime refuses anything else.
- **Places** are written `chapter:verse` (`3:16`). **Readings** are
  written in the plan-file format below, in their shortest writing.
- **Civil dates** (from P5.3) are `YYYY-MM-DD`, a proleptic Gregorian
  date with no time and no zone, years 0001 to 9999. A reading day is a
  civil date resolved once, at the edge, in the reader's time zone (E7);
  runtimes never carry instants as reading days. Times of day for
  reminders are wall-clock `HH:MM` with an IANA zone name.
- **Errors** are a `kind`, from the lists below, and a `message`. Kinds are
  the contract: the same input gives the same kind in every runtime.
  Messages are English for plan authors and logs, the same in both
  runtimes except where noted, and never shown to readers; reader-facing
  wording comes from the interface strings, keyed by kind.
- **Absent** means none: a field with no value is left out, never `null`
  (for example `words` for a book with no counts).

## Numbers

- **Rounding** is to the nearest whole number with halves away from zero
  (Swift's `rounded()`; in TypeScript `roundHalfAwayFromZero`, not bare
  `Math.round`, which rounds -2.5 to -2).
- **Whole numbers in data files** read as Swift's `Int(String)`: an
  optional `+` or `-`, then ASCII digits only (`+1` is 1; `1.5`, ` 1`,
  `１` are not numbers). Data files use LF line endings only; a CR makes
  a line malformed, though the line number reported may differ between
  runtimes.

## Scripture data

- **The registry** (`books.json`, format 1) is checked as it is read, and
  the first problem is reported, in this order: unreadable (not JSON of
  the expected shape, including an unknown convention, testament or
  malformed book id), unsupportedFormat, duplicateSource,
  duplicateConvention, missingConvention, unknownSource (a convention's),
  duplicateBook, then per book emptyName and redundantName, duplicateName
  and duplicateAbbreviation (per convention, ignoring case),
  duplicateCanon, duplicateOrder, then per canon canonWithoutOrder, per
  order repeatedBook, unknownBook, ordersDisagree, testamentsMixed and
  unknownSource, then its includes (unknownBook, includedTwice),
  unsourcedIncludes and unknownSource, and last bookInNoCanon and
  unusedSource. An unreadable registry's message is each runtime's own.
- **A versification** file has a line per book: id, first chapter, and
  each chapter's verses as a count (`31`, verses 1 to 31) or a range
  (`4-13`, which must start above 1). Fields are tab-separated; chapters
  are separated by spaces, and extra spaces between them are ignored.
  `#` starts a comment line. Errors: malformedLine, duplicateBook; checked
  against the registry, unregisteredBook and missingBook.
- **Word counts** have a line per chapter: id, chapter, and each verse's
  words, separated by single spaces (two spaces is malformed). Every
  chapter of a counted book must be present, once, with one count per
  verse. Errors: malformedLine, noSuchChapter, wrongVerseCount,
  duplicateChapter, missingChapter.
- **Positions.** A verse's position is its index in its book from 0,
  running on across chapters (Genesis 1:31 is 30, Genesis 2:1 is 31).
  Verse sets and word counts work in positions.

## References

A **passage** is a run of verses in one book under one scheme, from a first
verse to a last, both of which the scheme has; whole chapters are stored
as their verses, so `GEN 1` and `GEN 1:1-31` are equal (E30). A
**reading** is one or more passages in order, under one scheme; it may
cross books and repeat verses.

**The plan-file format** (`ReferenceFormat`, `parseReading`): passages
joined by exactly `; `, each a book id, one space, and one of `1`, `1-2`,
`3:16`, `3:1-21` or `3:16-4:3`. Numbers are one to three ASCII digits with
no leading zero; the hyphen is ASCII. Errors, the first passage's first:

| Kind | Example | Meaning |
|---|---|---|
| empty | `GEN 1; ` | nothing, or nothing between separators |
| malformed | `GEN 1–2`, `GEN 01`, `GEN 1-2:3` | not one of the five shapes |
| notABook | `Gen 1` | the first word is not a book id |
| redundant | `GEN 2-2` → `GEN 2` | a range written longer than it needs |
| unknownBook | `XYZ 1` | the scheme does not number the book |
| noSuchChapter | `GEN 51` | |
| noSuchVerse | `PSA 51:21` | English numbering has no such verse |
| endsBeforeItStarts | `GEN 3-2`, `GEN 1:9-5` | |

A reading's **shortest writing** writes whole chapters as chapters and a
range in one chapter without repeating the chapter; it reads back as the
same reading.

**What the reader sees** (`ReferenceFormatter`), under the chosen naming
convention (D29), full or abbreviated, with an en dash: "Genesis 1–2",
"John 3:16–4:3", "Psalm 23" for one psalm and "Psalms 120–122" for more,
"Jude 3–5" or "Jude" for a one-chapter book, each passage with its book
name ("Psalm 119:1–24; Psalm 120"). An abbreviation is used only where the
registry has one; an unregistered book shows its id. The one-psalm,
one-chapter-book and repeated-name rules are app conventions (E30).

*Example:* `JHN 3:16-4:3` is 21 + 3 = 24 verses; the reader sees "John
3:16–4:3", abbreviated "John 3:16–4:3" (SBL gives John no abbreviation).

## Verse sets and coverage

A verse set holds verses, each once, under one scheme. Union, intersection
and difference give a plan's unique verses, its repeats (verses given more
than once, in order of reading) and what it leaves out. A set is shown as
the fewest passages in the scheme's book order. Each chapter it touches is
**whole** (every verse in the set) or **partial** (at least one verse);
a partly read chapter is never counted as read.

*Example:* `JHN 3:16-4:3` then `JHN 3` gives 60 verses, 39 unique, repeats
`JHN 3:16-36`, one whole chapter (3) and one partial (4).

## Words and workload

A passage's words are the sum of its verses' counts; a reading's add each
passage, repeats included. A book with no counts makes the reading's words
absent, never zero.

Minutes are words ÷ 238 read silently and ÷ 183 aloud (Research finding
6). The reader sees a range from silent to aloud, each end rounded: never
below 1, to the nearest minute below 20, and to the nearest 5 from 20 up;
the high end is never below the low ("About 2 minutes" when both round
the same). The wording is "About 9–11 minutes. Estimates vary."

A plan's workload is its lightest, middle and heaviest reading by words;
the middle of an even number of readings is the mean of the two middle
ones, rounded. A plan with no readings has none.

*Example:* 734 words (Genesis 1) are 3.08 minutes silent and 4.01 aloud,
shown "About 3–4 minutes".
