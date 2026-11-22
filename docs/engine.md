# The reading engine

Specification version: **1**

Day by Word's reading logic has one specification, this file, and two
runtimes held to it: Swift's `ReadingEngine` (`Packages/ReadingEngine`)
for the app, its extensions and the catalog compiler, and the TypeScript
domain module (`web/src/lib/domain/`) for the web's server and browser
(docs/decisions.md E33). Both answer the same shared cases in
[tests/fixtures/](../tests/fixtures/README.md), and a rule is not done until
both do.

The first part covers identifiers, scripture data, references, verse
sets, word counts and workload (version 0, BUILD.md PM.15). The second
part, **version 1**, covers civil dates, plans, enrollments, the journal,
the three behaviors, the days ahead, returning, progress and reminders
(P5.1 to P5.12, P8.2a).
Both runtimes pass every case of both parts and state the version they
implement (`ReadingEngine.specificationVersion`, `specificationVersion`);
a web test checks that the two and the line above agree.

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
- **Civil dates** are `YYYY-MM-DD`, a proleptic Gregorian date with no
  time and no zone, years 0001 to 9999 ("Civil dates", below). A reading day is a
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

---

# Version 1: schedules, the journal, progress and reminders

Everything below is version 1 (BUILD.md P5.1). It covers what 1.0's eight
plans need: two schedule kinds (`sequence` and `day-of-month`) and three
behaviors. Sessions, church-year schedules and dates in the year come
after 1.0 (docs/roadmap.md). Rules marked *app convention* are Day by
Word's own choices, not a source's.

Three things stay apart (E2): the **plan version**, which never changes;
the **enrollment**, the reader's own arrangement for following it; and
the **journal**, what the reader did. The engine is a pure function of
them and a date: it never reads a clock, a time zone database or storage.

## Civil dates

A civil date is a year, month and day in the proleptic Gregorian calendar,
0001-01-01 to 9999-12-31, written `YYYY-MM-DD` with ASCII digits and
nothing else (`2027-1-4`, `2027-02-30` and `２０２７-01-04` are not dates).

- **Leap years:** divisible by 4, except centuries not divisible by 400.
- **Weekdays** are numbered as ISO 8601 does: 1 is Monday, 7 is Sunday.
  0001-01-01 is a Monday.
- **Arithmetic** is in whole days: a date plus or minus days, and the days
  from one date to another. Results outside the range are errors
  (`outOfRange`), never wrapped.
- **Parts:** the day of the month, the days in the month, and the day of
  the year (1 to 366).
- **The edge.** A client turns an instant into a civil date once, in the
  reader's time zone, and gives the engine that date as *today*. The
  engine never does this itself, so it gives the same answer everywhere.
  Each runtime has one such conversion beside the engine (Swift:
  Foundation's calendar in a given `TimeZone`; TypeScript: `Intl` in a
  given IANA zone), tested on its own.

*Example:* 2027-02-28 plus 1 day is 2027-03-01, a Monday; 2028-02-28 plus
1 day is 2028-02-29. From 2027-12-25 to 2028-01-01 is 7 days.

Errors: `malformed` (not `YYYY-MM-DD`), `noSuchDate` (`2027-02-30`),
`outOfRange`.

## Plans and assignments

A plan version is a plan id, a version, a schedule kind, the behaviors it
permits, the reading days a week it is paced for, and its assignments in
reading order, each with its id, its reading, and its words where the
catalog has them (docs/catalog-format.md).

- **Position** is an assignment's place in reading order, from 1. The
  reader sees positions ("Reading 12"), never ids.
- **A slot** is one thing a reader can mark. In a `sequence` plan it is an
  assignment. In a `day-of-month` plan each assignment recurs, so a slot is
  an assignment and the civil date it is appointed to.
- **Behaviors:** a `sequence` plan permits `pace` and `finish-date`; a
  `day-of-month` plan permits `calendar`. An enrollment's behavior must be
  one its plan permits.

## Enrollments

An enrollment is one reader's arrangement for following one plan version:
the plan's id and version, the behavior, the start date, the reading
days, the finish date and limit for `finish-date`, and a reminder time if
the reader wants one. It has an id of its own, and a reader may have
several, even of one plan. It is never stored as a record that can be
edited: it is what the journal's `enrolled` and `changed` events add up
to, so every arrangement the reader ever had can be read back. At 1.0 an
enrollment keeps the plan version it started with (corrections to a
published plan are P28.3).

The field names of the engine's answers are fixed by the shared cases as
each rule is built (P5.2 onward), in the style of the events below.

## The journal

The journal is a set of events. Nothing is ever changed or removed except
at the reader's request to delete their data (E3).

**Every event** has an `id`, a `kind`, the `enrollment` it belongs to, `at`
(the instant it was made, in UTC to the second, written exactly
`2027-03-01T11:02:03Z`), `zone` (the IANA zone the device was in: 1 to 64
ASCII letters, digits, `/`, `_`, `-` and `+`; the engine has no zone
database and checks only that) and `device` (an opaque name of 1 to 64
Unicode characters, counted as scalar values). The engine orders by `id`
and never reads `at` or `zone`; they are the record of when and where.

**Ids** are UUIDv7 (RFC 9562) in lowercase with hyphens:
`0195a7c2-3f10-7abc-8def-0123456789ab`. The first 48 bits are Unix
milliseconds, so ids sort by the time they were made. The engine makes one
from a millisecond count (0 up to, not including, 2^48) and ten random
bytes that the client supplies: the milliseconds, then `7` and the low
four bits of the first byte, the second byte, the variant bits `10` and
the low six bits of the third byte, and the last seven bytes as they are.
It checks the shape, the version (7) and the variant of any id it is
given. An enrollment's id is a UUIDv7 too. *A client's rule:* an event
that follows others in its enrollment (an undo above all) is given a
millisecond count later than theirs, so a slow clock cannot put it before
the event it answers.

| Kind | Its fields | Meaning |
|---|---|---|
| `enrolled` | `plan`, `version`, `behavior`, `start`, `readingDays`; for `finish-date` also `finish` and `limit`; optionally `reminder` | The reader started a plan. An enrollment's first event |
| `completed` | `assignment`, `date`; for a calendar plan also `appointed` | Read, on `date` |
| `partlyCompleted` | as `completed`, and optionally `verses` | Part of it read; `verses` says which, in the plan-file format |
| `skipped` | as `completed` | A scheduling decision, not a reading |
| `undone` | `target` | Takes back the event with that id |
| `changed` | `from`, and any of `start`, `readingDays`, `behavior`, `finish`, `limit`, `remaining`, `reminder` | The reader changed the arrangement, from that date |
| `paused` | `from` | Paused from that date |
| `resumed` | `from`; optionally `finish`, `remaining` | Resumed on that date |
| `returned` | `date`, `choice`; for `spread` and `moveFinish` also `finish`, `remaining` | The reader answered the welcome after a gap |
| `ended` | `date` | The reader stopped following the plan |

`date` is the civil date the reading happened, which the reader may set
to an earlier day (**late logging**: "Log an earlier day" records the
reading on the day it happened, never as today's). `appointed` is the
civil date of the calendar slot. `readingDays` is a list of weekday
numbers, ascending with none twice, at least one. `reminder` is a
wall-clock time `HH:MM` (`00:00` to `23:59`), or `off`. `version`,
`assignment`, `limit` and `remaining` are whole numbers from 1. `choice`
is one of the return choices ("Returning after a break"). `verses` is
kept as the text it is; only coverage reads it ("Progress").

`finish` and `remaining` set a schedule's basis ("Work toward a finish
date"), so they come together: an event with one and not the other is
malformed, and so is a change of `behavior` to `finish-date` without
`finish`, `limit` and `remaining`. A field its kind does not have is
ignored (a `returned` event's `finish` and `remaining` too, unless its
choice is `spread` or `moveFinish`).

**The fold.** State is computed from the whole journal and the plan
versions the engine is given, the same in any arrival order:

1. Put the events in order of `id`, as text. This is *journal order*.
2. An id that appears more than once is one event. If two copies differ
   in a field the engine reads, the journal is refused
   (`conflictingEvent`): ids do not collide by accident.
3. An event is **inert**, with a reason the fold reports, when it can mean
   nothing. This is decided in journal order, from the events before it
   alone, and once decided it never changes; the first reason that
   applies is given:
   - an `enrolled` event: `noEffect` (its enrollment is already
     enrolled), `unknownPlan` (the engine was not given that plan
     version), `notPermitted` (a behavior the plan does not permit, or
     `finish` or `limit` without `finish-date`);
   - any other event: `noEnrollment` (no `enrolled` event with that
     enrollment id, itself not inert, comes before it), then `ended`
     (the enrollment has an active `ended` event; only an `undone` event
     whose target is that event still has effect);
   - a marking event: `unknownAssignment` (not in that plan version),
     `wrongSlot` (`appointed` missing on a calendar plan or present on
     another, its day of the month not the assignment's, or before the
     start as it then stood);
   - `undone`: `noTarget` (the target is not an earlier event of the same
     enrollment, is inert, or is the `enrolled` event);
   - `changed`: `noEffect` (it has none of its fields), `notPermitted` (a
     behavior the plan does not permit, or `finish`, `limit` or
     `remaining` when the behavior, its own or else the one arranged for
     its `from`, is not `finish-date`);
   - `paused` and `resumed`: `noEffect` (pausing what is paused, resuming
     what is not: that is, whether the last active `paused` or `resumed`
     event before it is a `paused` one), and for `resumed`,
     `notPermitted` as for `changed`;
   - `returned`: `notPermitted` (a choice that is not one for the
     behavior arranged for its `date`).

   An inert event is kept and never deleted; it only does nothing.
4. **Undo.** An event is *active* unless an active `undone` event targets
   it. Undoing an undo makes its target active again: that is **redo**.
   So for `completed` C, then `undone` U1 of C, then `undone` U2 of U1:
   U2 is active, U1 is not, and C is active. Two undos of one event are
   one undo: both must be undone to bring it back.
5. **A slot's state** is what its last active marking event in journal
   order says: `completed` gives **read**, `partlyCompleted` **partly
   read**, `skipped` **skipped**; with none it is **unread**. A slot that
   is not unread is *settled*.
6. **The arrangement** on a date is the `enrolled` event's `behavior`,
   `readingDays`, `limit` and `reminder`, each replaced by the last active
   `changed` event in journal order that has the field and whose `from`
   is on or before that date. `reminder: off` leaves no reminder. `start`
   is not dated this way: the last active change to it replaces it
   outright. Nor is `finish`, which belongs to the schedule's basis
   ("Work toward a finish date").
7. **Paused days** run from an active `paused` event's `from` up to, not
   including, the next active `resumed` event's `from`; with no
   `resumed`, they run on.

*Examples.* A double tap makes two `completed` events with two ids for one
slot: the slot is read once, and one undo leaves it read (the other event
still stands), so a client disables the control after the first tap and
offers Undo for the event it made. A retry sends the same event, with the
same id, twice: one event. An accidental completion is taken back by
`undone`; the slot is unread again and the history shows both events.

The reader sees four states, in words and symbols as well as color:
"Read", "Part read", "Skipped", "Not yet read". Skipping says: "Skip this
reading. It won't count as read."

Errors, refusing the whole journal: `malformedEvent` (not an object, a
field missing, of the wrong type, or not a date, id or kind this version
knows) and `conflictingEvent`. Every event is checked before any is
folded, so a journal with a malformed event is `malformedEvent` whatever
else is wrong with it; the message names the first one as the events were
given, counting from 1, and the first field at fault in the order above
(`event 3 has no "date"`, `event 3's "date" is not a date`). A
`conflictingEvent` message names the lowest such id. Everything else is
inert.

## Reading days and rest days

A date is a **reading day** of an enrollment when it is on or after the
start, its weekday is among the reading days arranged for that date, it
is not a paused day, and it is not after the enrollment ended. Every
other date is a **rest day**. Rest days are intended, not missed: "Today
is a rest day in this plan."

A plan paced for five days a week suggests Monday to Friday and one paced
for seven suggests every day; the reader chooses, and may choose more or
fewer days than the plan is paced for.

*Example:* started Monday 2027-03-01 with reading days 1 to 5, the first
week's reading days are 1 to 5 March; 6 and 7 March are rest days.

## Today

For one enrollment and a date, the engine gives a **status**, the reading
or readings for the day, and the next unread reading:

| Status | When | The reader sees |
|---|---|---|
| `upcoming` | before the start date | "This plan starts on 1 March." |
| `reading` | there is a reading for today, not yet done | the reading, with Mark read |
| `done` | today's reading is read or partly read | "That's today's reading." |
| `open` | a reading day with nothing left for today | "Nothing more is scheduled today." |
| `rest` | a rest day | "Today is a rest day in this plan." |
| `paused` | a paused day | "This plan is paused." |
| `finished` | a sequence with no unread reading | "You've reached the end of this plan." |
| `ended` | the reader stopped | (shown only among finished plans) |

The first that applies is the status: `ended`; `finished`; `upcoming`;
`paused`; `rest`; and then, on a reading day, `reading`, `done` or `open`
as the behavior says.

With the status the engine gives whether today is one of the reader's
reading days, the readings to read today in reading order, the slots read
or partly read with today's date, and, on every status but `upcoming`,
`finished` and `ended`, a sequence's next unread reading, so the reader
can read ahead on a rest day or after today's reading. Reading ahead is
never suggested. Which rules apply is settled by the behavior arranged
for today.

## Continue at my pace

For `sequence` plans. "Read the next reading whenever you read. If you
miss a day, nothing is lost: your next reading waits for you, and your
finish date moves."

- **Next** is the first unread assignment in reading order. A reading the
  reader marked partly read or skipped is settled and the plan moves on;
  it stays in history as what it is, and the reader can mark it read later.
- **Today:** on a reading day the status is `done` once any reading is
  marked read or partly read with today's date, and `reading` until then,
  with the next reading as today's. A skip does not make the day done:
  the next reading takes its place. A reading logged for an earlier day
  is that day's, so today's is still to read.
- **Finished** means no assignment is unread. Completion is counted
  apart: "85 of 89 readings read, 2 part read, 2 skipped."
- **The finish date** is projected, never promised. With *r* unread
  readings, and counting reading days from the first open day (today when
  today's status is `reading`, otherwise the next reading day):
  - *at the plan's pace*, one reading each reading day, it is the *r*-th
    reading day;
  - *at the reader's recent pace*, take the 28 days before today (not
    before the start): *a* readings marked read or partly read with dates
    in them, over *b* reading days. When *b* ≥ 5 and *a* ≥ 1 it is the
    ⌈*r* × *b* ÷ *a*⌉-th reading day; otherwise there is none yet.
  The window is the 28 dates ending yesterday, or from the start when
  that is later. A day that never comes (a pause with no end lies ahead)
  gives no date. On a paused day, and once finished or ended, there is
  no projection.
- **Ahead and behind.** A pace plan has no schedule to be behind. The
  engine gives the two dates and, for comparison, the date the plan would
  have finished at one reading every reading day since the start; the
  reader is told only "Your finish date is now 14 March", and only where
  they look for it.

*Example:* a 10-reading plan started Monday 2027-03-01, reading days 1 to
5. Readings 1 to 3 are read on 1, 2 and 3 March; the reader is away, and
opens the app on Tuesday 9 March. Next is reading 4, today's status is
`reading`, and 7 readings remain: at the plan's pace the finish is the
7th reading day from 9 March, Wednesday 17 March. The recent window is 1
to 8 March: 3 readings over 6 reading days, so ⌈7 × 6 ÷ 3⌉ = 14 reading
days, Friday 26 March. Had no day been missed it would have been Friday
12 March.

## Work toward a finish date

For `sequence` plans. "Choose when you'd like to finish. If you miss
days, Day by Word can spread the readings you missed over the days ahead,
up to a limit you set, or move your finish date. You'll see the change
before it happens."

**The schedule** is a *basis*: a first day *A*, a finish date *F*, and
*R*, the readings unread when it was set. Enrolling sets one (*A* the
start, *R* every reading). A `changed`, `resumed` or `returned` event
that carries `finish` and `remaining` sets a new one from its own date;
the last active such event in journal order is the basis. An *R* above
the plan's readings counts as all of them. The reader's **limit** is the
most readings on one reading day they accept.

- **Scheduled days** are the reading days from *A* to *F*, *N* of them.
- **The target** after the *i*-th scheduled day is (total − *R*) +
  ⌊*i* × *R* ÷ *N*⌋ settled readings, so readings are spread as evenly as
  whole readings allow, and all are due after *F*. Before *A* it is
  total − *R*. With no scheduled days everything is due from *A*.
- **Each day's share** is the target after it less the target before it;
  a day that is not a scheduled day has none. The *k*-th of the basis's
  readings is expected on scheduled day ⌈*k* × *N* ÷ *R*⌉; that gives the
  coming week and the printable checklist. When *u* readings are unread,
  the *j*-th of them is the (*R* − *u* + *j*)-th of the basis's, kept
  within 1 to *R*.
- **Outstanding** readings are the target before today less the readings
  settled, when that is above zero.
- **Today** shows the next unread readings: as many as bring the settled
  readings to today's target, but with those read or partly read today
  never more than today's share (or one, when readings are outstanding
  and today's share is none): a backlog is never put on one day. When
  there are none to show, the status is `done` if the reader has read
  today and `open` if not. Skipping a reading settles it, so it leaves
  today's count without being a reading.
- **Before the reader accepts** a finish date, the engine gives the
  number of scheduled days, the least and most readings on one day
  (⌊*R* ÷ *N*⌋ and ⌈*R* ÷ *N*⌉; all *R* when there are no scheduled
  days), and the words of the heaviest day ahead, from which the
  interface shows minutes ("About 20–25 minutes on the heaviest day.
  Estimates vary."). The words are absent when a reading has no count.
- **A pause takes its days out of the schedule**, so the readings fall on
  fewer days. Nothing is moved for the reader: the engine reports the new
  most on a day and the finish that fits the limit, and resuming may
  carry a new basis.
- **A target beyond the limit** is never met by leaving readings out. The
  engine says how many readings a day it would need (the most, above),
  and the earliest finish date that fits the limit: the ⌈*R* ÷ limit⌉-th
  reading day from *A*. The interface offers that later date or a
  shorter plan: "To finish by 31 March you'd read up to 4 readings a day.
  At 2 a day you'd finish on 28 April."

*Example:* a 10-reading plan started Monday 2027-03-01, reading days 1 to
5, finish Friday 2027-03-05, limit 2. Five scheduled days: targets 2, 4,
6, 8, 10, so 2 readings each day. The reader reads 2 on Monday and none
on Tuesday or Wednesday. On Thursday the target before today is 6, with 2
settled: 4 readings are outstanding, and today shows the next 2 (readings
3 and 4), not 6.

## Follow the calendar

For `day-of-month` plans. "Read the readings appointed for each date.
Today's readings stay on today, as the calendar sets them. Readings you
missed stay in your history, and you can read them whenever you like."

- **The appointment** for a date on or after the start is the assignment
  whose id is the date's day of the month. There is no next reading: the
  appointment is the day's reading.
- **Today:** on a reading day the status is `reading` while today's slot
  is unread, `done` once it is read or partly read (on whatever day), and
  `open` if the reader skipped it.
- **It never moves.** A missed appointment stays unread in history under
  its own date; nothing is carried to another day, and rejoining marks
  nothing read.
- **Rest days and pauses do not stop the calendar.** The appointment is
  given on every date; the engine also says whether today is one of the
  reader's reading days, which governs reminders, the welcome after a gap
  and the streak, never the appointment.
- **Short months** (*app convention*). A month without a 29th, 30th or
  31st does not appoint those readings; they are not added to another
  day, which would change the day's workload without the reader asking.
  On the month's last day the engine lists them, and the interface says
  so: "April has 30 days, so this plan has no reading for the 31st this
  month."
- **Missed** appointments are the unread slots from the start to
  yesterday, paused days excluded and rest days included. The count is
  given and shown only where the reader asks.
- A calendar enrollment is never `finished`; it runs until the reader
  ends it.

*Example:* enrolled on 2027-04-28. On Friday 30 April the appointment is
reading 30, and reading 31 is listed as not appointed this month. On 1
May it is reading 1. If the reader was away from 2 to 5 May, on 6 May the
appointment is reading 6 and four slots are unread in history.

## The days ahead

For a plan's sample week, the coming week and the printable checklist,
the engine lists the dates from today on, each with whether it is one of
the reader's reading days and the readings expected on it. It is Today's
own answer for each date in turn, supposing the reader reads what each
day shows and nothing more, so the list never disagrees with what Today
will say.

- **Today** has today's readings.
- **Pace:** each later reading day has one reading, the next unread
  after those listed before it.
- **Finish-date:** each later reading day has as many as bring the
  settled readings to that day's target, and never more than the day's
  share (or one, where readings are outstanding and the day has no
  share), as on Today.
- **Calendar:** every date on or after the start has its own
  appointment, on rest days and paused days too, unless it is already
  settled or the month does not appoint it.
- A sequence's rest days, paused days and dates before the start have no
  readings, and an ended enrollment has none on any date.
- **A sample week** before the reader starts is this list for a candidate
  `enrolled` event, as for any preview ("Returning after a break").

*Example:* the finish-date example on Thursday 2027-03-04, with readings
1 and 2 read: Thursday has readings 3 and 4, Friday 5 and 6, and from
Monday, past the finish date, one reading each reading day: 7, 8, 9, 10.

## Returning after a break

"Welcome back. Here's where you left off." Never a count of days.

- **The anchor** is the latest of: the day before the start; the latest
  date on which the reader read (an active `completed` or
  `partlyCompleted`, not after today); the date of the last active
  `returned` event; and the day before the last active `resumed`.
- **A gap** is two or more reading days strictly between the anchor and
  today (*app convention*: one missed day is simply a day). The welcome
  is offered while there is a gap, and answering it (a `returned` event
  dated today) ends it. It is not offered before the start, on a paused
  day, or once the plan is finished or ended. A skip is not a reading and
  does not move the anchor; a reading logged today for an earlier day
  does.
- **The choices** depend on the behavior, and each comes with its effect
  worked out before anything changes:

| Choice | For | Effect | The preview says |
|---|---|---|---|
| `continue` | pace, finish-date | Nothing is rescheduled | "Your next reading will be Mark 5." and, for pace, the projected finish |
| `spread` | finish-date | A new basis from today to the same finish, over the unread readings | "2 readings a day until 26 March." Offered only within the limit, and only while a reading day is left before the finish; beyond the limit the engine says what limit it would need |
| `moveFinish` | finish-date | A new basis from today at the present daily amount (the basis's most on a day; never above the limit, and at least one), finishing on the reading day that needs | "Your finish date moves to 14 March." Offered when that is later than the present finish |
| `rejoin` | calendar | Nothing is marked | "Today's reading is Proverbs 6. The readings you missed stay in your history." |

- **A preview is the fold itself**: the engine's answer for the journal
  with the candidate event added after every other, beside its answer
  without. Nothing is written until the reader confirms, and the
  confirmed event can be undone like any other. If the candidate would be
  inert, the preview says why and nothing changes.

*Example:* the finish-date example above, opened on Monday 2027-03-08
after the finish date. Eight readings are unread. `spread` is not offered
(no scheduled days remain); `moveFinish` keeps 2 a day from today: 4
reading days, finishing Thursday 11 March.

## Changing an enrollment

A `changed` event alters reading days, the start date, the behavior (to
another the plan permits), the finish date, the limit or the reminder,
from its `from` date. History is untouched: marks are kept whatever
changes, and a slot keeps its state. The interface shows the engine's
answer with and without the change before the reader confirms, as for a
return choice. On a `finish-date` arrangement a change to the reading
days or the finish date, or a change to that behavior, carries a new
basis: the finish given, or else the present one, over the readings
unread now. A change of the limit or the reminder alone carries none.
Moving the start date later never removes a reading made before it.

*Example:* the pace example on 9 March, changing reading days from 1–5
to 1–6 from that date: the finish at the plan's pace moves from Wednesday
17 March to Tuesday 16 March.

Pausing ("This plan is paused.") stops reminders, the welcome and the
streak for the paused days, and nothing else; the reader can still read
and mark.

## Progress

Records describe activity. They do not measure faithfulness, maturity or
understanding, and no wording may suggest they do (AGENTS.md §3).

- **Assignments** in each enrollment: read, partly read, skipped and
  unread, and the total. For a calendar enrollment the total is the slots
  appointed from the start to today (or to the day it ended), paused days
  excluded, together with any slot the reader settled outside those days
  (on a paused day, or read ahead), so the four states always add up to
  the total. "62 of 89 readings read."
- **Recent reading days:** the seven dates ending today, each with
  whether the reader read on it (any active `completed` or
  `partlyCompleted` with that date, in any enrollment) and whether it was
  a reading day of any enrollment. A reading begun one day and finished
  the next is two days read, though its slot keeps only the later mark.
- **A finished sequence asks nothing** after the last day the reader
  marked in it (*app convention*): its later dates are not reading days
  here or for the streak, so finishing a plan never ends a streak.
- **Coverage** is across all enrollments, each verse once: every reading
  marked read, and the stated verses of readings marked partly read, as
  far as they are verses of that reading. A reading marked partly read
  with no verses stated (or none that are its own, or text that is not a
  reading) adds no verses; its chapters count as partial and its books as
  explored. Chapters are whole or partial as verse sets define, so a
  partly read chapter is never counted as read. Repeats add nothing, and
  a skipped reading covers nothing.
- **Books explored** are the books coverage touches, in the scheme's
  order, each with its verses read of the verses it has.
- **Plan completion is not coverage.** Each is reported on its own;
  finishing a plan says nothing about the whole Bible unless its verses
  do.
- **The streak** (D17, off unless the reader turns it on) is the number
  of consecutive reading days, of any enrollment that is not ended, on
  which the reader read, counting back from today, or from the last
  reading day before today when today is not yet read. Rest days and
  paused days neither break it nor add to it, even when the reader read
  on one. It is shown small, never in a notification, and never with
  words of loss.

*Example:* reading days 1 to 5; read Thursday and Friday, nothing at the
weekend, read Monday. On Tuesday morning the streak is 3: the weekend
were rest days, and Tuesday is not yet counted either way.

## Quiet celebrations

Day by Word notices four things the reader did and says each in a
sentence, on the day it happened (BUILD.md P11.2): returning after a gap,
finishing a book, finishing a plan, and keeping the reading days they
chose for a week. They are words, never confetti, badges or points; they
never compare the reader with anyone, count days, or mention what was not
read; and like every record they describe activity.

For a date *D* the engine lists them: for each enrollment in the order
the reader started them, its return, the books it finished (in the
scheme's book order) and its finishing; then the week's rhythm. An
enrollment that ended on or before *D* has none. Each rests on marks
*dated* *D*, the day the reading happened, so a reading logged today for
an earlier day belongs to that day, and a celebration is for its own day,
not every day after. Nothing is stored: the list is worked out again
whenever it is asked for.

**The record before a date** is what the enrollment's active marking
events dated before it give alone, as if every mark dated on or after it
were left out; **the record through** a date includes the marks dated on
it.

- **Returning after a gap** (`returned`): the reader read in the
  enrollment on *D* (an active `completed` or `partlyCompleted` dated
  *D*) and on an earlier date; *D* is on or after the start and not a
  paused day; the plan was not finished in the record before *D*; and two
  or more reading days lie strictly between the anchor and *D*. The anchor
  is the latest of the day before the start, the last earlier date the
  reader read in it, and the day before the last active `resumed` whose
  `from` is on or before *D*. This is the gap of "Returning after a break"
  as it stood that morning, except that answering the welcome is not
  reading: a reader who answered it yesterday and reads today returns
  today. A first reading is a beginning, not a return. "You've picked up
  where you left off."
- **Finishing a book** (`finishedBook`, with the book): every verse of the
  book is in the enrollment's own coverage ("Progress", for this
  enrollment alone) in the record through *D*, and was not in the record
  before *D*. Because the coverage is the enrollment's own, a second plan
  through the same book celebrates it again. A skipped or part-read
  chapter leaves the book unfinished until it is read. "You've read all of
  Ruth."
- **Finishing a plan** (`finishedPlan`): a sequence with no unread reading
  in the record through *D* that had one in the record before *D*. A skip
  of the last reading finishes it too, since the plan has come to its end;
  how much was read is counted apart, on Progress. A calendar plan never
  finishes. "You've finished Gospels at your pace."
- **Keeping a rhythm** (`keptRhythm`, across enrollments): in *D*'s week
  (Monday to Sunday, ISO 8601), *D* is the last reading day, the week has
  at least two, and the reader read on every one of them up to *D*. A
  reading day is one of any enrollment, as for the recent days and the
  streak (a finished sequence asks nothing after its last marked day), and
  a day is read when an active `completed` or `partlyCompleted` in any
  enrollment is dated on it. Rest days and paused days are not asked
  about. A week with one reading day says nothing (*app convention*: a
  rhythm takes at least two). "You've read on each of your reading days
  this week."

Nothing is said about a day not read; no celebration mentions the streak
or appears in a notification.

*Example:* reading days 1 to 5, in a plan of Ruth and then Jonah. The
reader reads Ruth 1 on Monday 2027-03-01, nothing from Tuesday to
Thursday, and Ruth 2 to 4 on Friday 5 March. On Friday they have returned
(three reading days lay between Monday and Friday) and finished Ruth; the
week is not kept, since Tuesday to Thursday were not read. If they read
Jonah 1 to 4 on Monday to Thursday of the next week and Jonah's last
chapter was the plan's last reading, Thursday finishes Jonah and the plan,
and keeps the week: once the plan is finished, Friday asks nothing.

## Reminders

The engine works in wall-clock times and never in instants: it is given
the local date and time now, and returns the local dates and times at
which reminders should fire. The device schedules them by wall-clock time
in its present zone, and asks again whenever a reading is marked, a
setting changes, or the time zone changes. Quiet hours, the most a day
and snoozes are the device's settings, not events; only an enrollment's
reminder time is in the journal.

Given the enrollments, the journal, now, quiet hours, the most reminders
a day, any snoozes, and a window size:

1. **Candidates.** For each enrollment that has not ended and is not
   finished, one on each of its reading days from today on (a paused day
   is not one), at the reminder time arranged for that day. Today's is
   left out unless today's status is `reading`, and when its time, after
   rule 3, is not still to come: at its own minute a reminder has passed.
   A `sequence` enrollment gets no more candidates than it has unread
   readings. A calendar enrollment gets none on a date whose appointment
   is already settled, or that appoints nothing.
2. **A snooze** (an enrollment, a local date and a time) adds one
   candidate at its time, if that is still to come after rule 3 and the
   enrollment's status today is `reading`: the reading it was about is
   still to read. A snooze for an enrollment the journal does not have is
   ignored.
3. **Quiet hours** run from one wall-clock time up to another and may
   cross midnight; hours that end where they begin are none. A candidate
   inside them moves to their end when that is later the same day, and is
   dropped otherwise: a reminder never arrives the next morning about the
   day before.
4. **One at a time.** An enrollment has one candidate at one date and
   time; where a snooze lands on the day's own reminder, that reminder
   stands.
5. **The most a day:** on each date the earliest are kept, in the order
   the reader's plans are listed when times tie. A snooze counts.
6. **The window:** the earliest candidates overall, up to the window
   size. iOS keeps at most 64 pending requests (Research finding 9), so
   the app asks for 60 and refills as days pass. The engine looks no
   further ahead than today and the 365 days after it (*app convention*).
7. **Never about the past.** No reminder concerns a missed day, counts
   days, or mentions the streak. The text is the plan and the reading:
   "Gospels at your pace: Mark 4:1–20.", or only the plan's name when the
   reader hides passage details. Each reminder comes with the reading it
   is about: a calendar date's own appointment, or a sequence's next
   unread reading as things stand now, on every one of its days. If the
   reader reads nothing that reading is still next, and marking one asks
   the engine again, so a reminder never names a reading that has been
   read.

*Daylight saving time and travel.* Because the times are wall-clock, a
07:00 reminder stays at 07:00 when the clocks change. A time the clock
skips (02:30 on the night clocks go forward) is delivered by the system
at the next minute that exists, and a time that happens twice fires once,
the first time. After travel the device gives the engine the new local
now; reminders keep their wall-clock times in the new zone, and one whose
time has already passed there today is left out. Each runtime's edge
turns an instant into the local date and time (Swift:
`LocalDateTime(_:in:)`, tested for both clock changes and for travel);
the web has no reminders at 1.0.

*Example:* a reminder at 07:00 on reading days 1 to 5; now is Friday
2027-03-12 at 07:30 with today's reading unread. The first candidates are
Monday 15 March 07:00, then Tuesday 16 March. With quiet hours 22:00 to
08:00 each moves to 08:00, and today's, at 08:00, is still to come, so it
is first.

## Choosing a plan

The engine recommends plans from the reader's answers to a few practical
questions (BUILD.md P9.1, P9.2), by the fixed rules below: never by
popularity, never by anything the reader did not say, and never by AI
(D12, D23). The same answers and catalog always give the same
recommendations, in the same order.

**Goals.** The catalog groups its plans by goal (`catalog/goals.json`,
docs/catalog-format.md), in this order: `begin` (a place to begin),
`whole-bible`, `new-testament`, `gospels`, and `psalms-proverbs`. A plan
may be in more than one goal.

**The answers**, any of which may be left as "not sure":

- what the reader hopes to read: a goal;
- how long a reading may take: `short` (about 5 minutes), `medium` (about
  10), or `long` (15 minutes or more);
- how many days a week the reader expects to read, 1 to 7 (the picker
  offers 7, 5 and 3).

**A candidate** is a plan as the catalog gives it: its id, its goals, its
schedule, the reading days a week it is paced for, how many readings it
has, and the words of its typical (middle) reading, whose minutes are as
"Words and workload" gives them.

**The rules:**

1. *Which plans.* With a goal, the plans in that goal; without one, every
   plan.
2. *Fitting.* The time fits when the typical reading's lower (silent)
   minutes are no more than the answer's: 5 for `short`, 10 for `medium`,
   any for `long`. The days fit when the plan is paced for no more reading
   days than the reader expects. An unanswered question fits every plan.
3. *Order.* (a) Plans that fit both come first, then those that fit one,
   then the rest; (b) without a goal, plans in `begin` come before the
   others; (c) then the plan whose pace is nearer the reader's days
   (the difference between the plan's reading days and the reader's;
   none when unanswered); (d) then the plan whose typical reading's lower
   minutes are nearer the answer's time (5, 10 or 15; none when
   unanswered); (e) then the catalog's order.
4. *How many.* The first three, or all of them when there are fewer.

**Each recommendation** gives the plan; the goal it answers (the reader's
goal, or `begin` when the reader gave none and the plan is in it); its
typical reading's minutes, low and high; whether the time fits and
whether the days fit (each absent when unanswered); the reader's days;
and, for a `sequence` plan, the readings a week (the fewer of the
reader's days and the plan's, or the plan's when unanswered) and the
weeks it takes: its readings divided by the readings a week, rounded up
(the week its last reading falls in; a plan's page gives the same at the
plan's own pace). A
`day-of-month` plan has no weeks: it has a reading for each date. The
reader sees each fact as a reason in words ("You said about 10 minutes:
its readings take about 9–11"), and the caveat that estimates are
approximate.

*Example:* a reader who hopes to read the whole Bible, has about 10
minutes, and reads five days a week, with two whole-Bible plans: one
paced for seven days at 9–11 minutes and 365 readings, one paced for five
at 12–16 minutes and 260. Each fits one answer; the five-day plan's pace
is the reader's, so it comes first (52 weeks, its readings longer than
the reader said), then the seven-day plan (73 weeks at five readings a
week).
