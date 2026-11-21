# Day by Word's own plans: their rules

Each original plan is built from verse data under a rule stated here
(AGENTS.md §6), never typed from memory and never taken from another
publisher's version of a familiar plan. `scripts/plans.swift` is the rule
in code: it writes each plan file's schedule (everything after the `---`
line), and `make check` fails if a schedule is not what its rule gives. A
plan's front matter is written by hand and reviewed (docs/editorial.md).

~~~sh
swift scripts/plans.swift generate   # rewrite the schedules
swift scripts/plans.swift check      # part of make check
swift scripts/plans.swift facts      # readings, chapters and words of each plan
~~~

The data is the repository's own: the English (KJV) chapter and verse
counts and the World English Bible's word counts (docs/scripture.md,
`catalog/SOURCES.md`). No Scripture text is read or kept (D13). The
compiler then checks every reference and computes each plan's coverage,
repeats, omissions and workload (docs/catalog-format.md); those computed
facts, never this page, are what a plan's page states.

## Balanced readings

Plans "sized" or "balanced by reading time" use one rule. Chapters, in
their order, are divided into a given number of readings so that:

- every reading is one or more whole chapters, in order; no chapter is
  split and none is left out or repeated;
- the readings are as even in words as that allows: of every way to
  divide the chapters into that many consecutive readings, the one with
  the smallest sum of the squares of the readings' word counts is taken
  (of equal ones, the one that breaks later).

Words stand in for reading time (238 words a minute read silently, 183
aloud; docs/engine.md, "Words and workload"). A long chapter stands as a
reading on its own, and short chapters are read together, so readings
still differ in length; each plan's page gives its lightest, middle and
heaviest reading.

## The plans

| Plan | Rule |
|---|---|
| `gospels-at-your-pace` | Matthew, Mark, Luke and John, each divided on its own by the balance rule into the whole number of readings nearest to its words ÷ 1,350 (17, 11, 18 and 14: 60 readings). No reading runs from one Gospel into the next. Paced for five days a week: twelve weeks. |
| `bible-in-a-year` | The 66 books of the Protestant canon in its printed order, in 365 readings. The readings are shared between the testaments by their words (280 and 85), and each testament is divided on its own by the balance rule, so no reading runs from Malachi into Matthew; within a testament a reading may run from one book into the next. |
| `proverbs-through-the-month` | A day-of-month plan: the reading for day *n* is Proverbs *n*. What a short month does is the engine's rule (docs/engine.md, "Follow the calendar"). |

**Why 1,350 words** (agent, 2026-11-21): it gives 60 readings of about 6
to 7 minutes, which is twelve weeks at five readings a week; one chapter
a reading (89 readings of 2 to 9 minutes) is less even, and longer
readings suit a first plan less.

## Changing a plan

A published schedule changes only as a new version of its plan
(docs/catalog-format.md, "Stable assignment ids"; P28.3). Changing a rule
here, the word counts, or the versification changes what `generate`
writes, so `check` fails until the plan's version is raised and the
change reviewed.
