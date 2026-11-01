# The catalog format

Every plan is one plain-text file in `catalog/plans/`, named for its id
(`catalog/plans/gospels-at-your-pace.plan`), written so it can be reviewed
line by line (E13). The compiler (`make catalog`, BUILD.md P4.3) reads it,
checks every reference and claim, and writes it into `Catalog.sqlite`;
nothing reads plan files at run time. The scripture data it is checked
against is described in `docs/scripture.md`, and its rights in
`catalog/SOURCES.md`.

## A plan file

Front matter of `key: value` lines, a line holding only `---`, then the
schedule. Lines starting with `#` are comments anywhere, and blank lines
are ignored. A value continues on following lines indented by two spaces,
which join with single spaces.

```
id: example-gospel-sampler
title: A Gospel sampler
version: 1
creator: Day by Word
summary: Five short readings from the Gospels, for a first week of
  reading.
suits: Readers trying a daily reading for the first time.
schedule: sequence
behaviors: pace, finish-date
reading-days: 5
coverage: selection
canon: protestant
books: MAT, MRK, LUK, JHN
limitations: Short passages chosen for a first week; it reads no book whole.
instructions: Read one passage a sitting, in any Bible.
source: An original plan by Day by Word.
rights: daybyword-original
review: checked
---
1	MRK 1:1-20
2	LUK 15
3	JHN 3:1-21
4	MAT 5:1-16
5	JHN 20:1-18; JHN 20:19-31
```

## Front matter

Every key is required, appears once, and comes in this order; an unknown
key is an error. Reader-facing values follow AGENTS.md §3: what the plan is,
whom it suits, its workload and coverage, and its limitations, never a
sermon.

| Key | Value |
|---|---|
| `id` | The plan's id (`PlanID`, docs/urls.md), the same as the file name. It never changes. |
| `title` | The exact title, with its edition where it has one. |
| `version` | A whole number from 1, raised with every published change (P4.6). |
| `creator` | Who made the plan: "Day by Word" for original plans. |
| `summary` | A short explanation of the plan, for its page. |
| `suits` | Whom it suits, in practical terms (time, goals, reading days). |
| `schedule` | `sequence` (numbered readings in order) or `day-of-month` (a reading for each day of the month). |
| `behaviors` | The behaviors the reader may choose, joined by `, `: `pace` and `finish-date` for a sequence, `calendar` for a day-of-month plan. |
| `reading-days` | The reading days a week the plan is paced for, 1 to 7. The reader chooses which days; the rest are rest days. |
| `coverage` | The claim the compiler checks (P4.4): `whole-bible` (every verse of the canon), `books` (every verse of each listed book), or `selection` (passages from the listed books, with no claim to cover them). |
| `canon` | The canon the plan assumes, by its id in `books.json`. |
| `books` | The books it reads from, by USFM id in canonical order, joined by `, `. Every reading's books must be listed, and every listed book read from. A `whole-bible` plan writes `all`, meaning the canon's books. |
| `limitations` | What the plan does not do, stated beside what it does. |
| `instructions` | How to follow it, plainly. |
| `source` | The source note shown on the plan page. |
| `rights` | Its entry in `catalog/SOURCES.md`. |
| `review` | Its review level (`docs/editorial.md`): `checked`, `reviewed`, or `expert`. |

## The schedule

One line per assignment: its id, a tab, and its reading in the plan-file
reference format (`docs/scripture.md`). Every reading is checked against
the English versification.

- **A sequence** numbers its assignments from 1 in the order they are read,
  one line each, with no gaps when first published.
- **A day-of-month plan** has one line for each day from 1 to 31, keyed by
  the day. What happens on the 31st, and on the 29th and 30th of February,
  belongs to the engine's rules for the calendar behavior (P5.7), and the
  plan's `instructions` say it plainly.

## Stable assignment ids

An assignment's id is how the journal records it (E3), so a reader's
history must keep meaning the same reading across versions of the plan:

- An id is never reused for a different reading and never renumbered.
- A correction that changes a reading's references keeps its id (P4.6 and
  P28.3 cover what an enrollment then shows).
- A reading added to a sequence after publication takes the next unused
  number and its line goes where it is read, so a sequence's ids are in
  order only until its first insertion. "Reading 12" on Today counts the
  reading's place in the sequence, not its id.
- A reading removed from a sequence leaves its id unused for good.
- A day-of-month plan's ids are its days, so they never change.

## What the compiler adds

The compiler computes, and never takes from the file: each plan's unique
coverage, repeats, and omissions (P4.4), its workload from the word counts
(P3.7), and the sample week. It refuses a plan whose claim the schedule
does not support.
