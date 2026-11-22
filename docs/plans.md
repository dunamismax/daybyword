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
| `bible-in-a-year-five-days` | The Bible in a year's rule in 260 readings, five a week for 52 weeks: shared between the testaments by their words (199 and 61), each testament balanced on its own. |
| `new-testament-in-a-year-five-days` | The New Testament's 260 chapters in printed order, one a reading: five a week for 52 weeks. |
| `psalm-a-day` | The psalms in order, one a reading, except Psalm 119, read in runs of 16 verses (two of its 8-verse stanzas): 11 readings, so 160 in all. |
| `story-of-scripture` | Not a computed rule but an editorial selection, listed in `scripts/plans.swift` with what each reading tells: 51 narrative passages in the order the story unfolds, one episode (or two short ones from the same part of the story) a reading, whole chapters where the episode fills them. `generate` writes them as listed and refuses one not in its shortest writing. |
| `pauls-letters` | The chapters of the thirteen letters that open with Paul's name (Romans to Philemon), in printed order, one a reading: 87 readings. |

**Why 1,350 words** (agent, 2026-11-21): it gives 60 readings of about 6
to 7 minutes, which is twelve weeks at five readings a week; one chapter
a reading (89 readings of 2 to 9 minutes) is less even, and longer
readings suit a first plan less.

**Why two stanzas of Psalm 119** (agent, 2026-11-22): the psalm has
2,334 words, ten times the middle psalm (231); two stanzas are 199 to 241
words, about as long as a typical psalm, and the stanzas are the psalm's
own divisions, which many English Bibles mark.

**Why one chapter a reading** for the New Testament and Paul's letters
(agent, 2026-11-22): the New Testament has exactly 260 chapters, five a
week for a year; Paul's chapters run from 1 to 6 minutes, short enough to
read slowly, and a reader with a paper Bible finds a chapter at once.
Paul's letters leave out Hebrews, which names no author; the plan says so.

**How the Story of Scripture was chosen** (agent, 2026-11-22): from the
narrative books only, the episodes where the story's course turns (its
beginning, Israel's ancestors, the exodus and Sinai, the land, the
judges and the kings, the division and fall of the kingdoms, exile and
return; in the Gospels, Jesus' birth, work, teaching, death and
resurrection; the first churches in Acts) and the Bible's last two
chapters. No psalms, wisdom books, letters or prophets' oracles; the
order is the story's, which is mostly the printed order (Daniel 6, set
in the exile, comes before Ezra's return). Readings of about 4 to 5
minutes, five a week, for an introduction of about ten weeks. Another
selection could tell the story differently, and the plan page says so.
No other plan or publisher's selection was consulted.

## Changing a plan

A published schedule changes only as a new version of its plan
(docs/catalog-format.md, "Stable assignment ids"; P28.3). Changing a rule
here, the word counts, or the versification changes what `generate`
writes, so `check` fails until the plan's version is raised and the
change reviewed.
