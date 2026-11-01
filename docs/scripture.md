# Scripture data

What Day by Word knows about the Bible's books, chapters, verses, and
words, and where it comes from. It is all data and numbers: Day by Word
never stores or shows Bible text (D13). The code is in
`Packages/ReadingEngine`, the data in `catalog/scripture/`, and each
source's rights record in `catalog/SOURCES.md`. Decisions E27, E28, E30,
and E31 in `docs/decisions.md` give the reasons.

## Books, canons, and names

`catalog/scripture/books.json`, read by `BookRegistry` (E27):

- **Books** are USFM 3.0 ids (`GEN`, `1SA`, `JHN`), 78 in all: the 66, the
  seven deuterocanonical books, and the Greek additions to Esther and Daniel
  and the Letter of Jeremiah, which some Bibles print apart.
- **Canons** are sets of books with one or more printed orders: Protestant
  (66 books) and Catholic (73, in two orders, because printings disagree on
  where 1 and 2 Maccabees stand). A canon's `includes` says which book holds
  material other Bibles print apart (Catholic `DAN` holds `S3Y`, `SUS`, and
  `BEL`).
- **Names** follow the reader's chosen convention (D29): common English
  (the default, with SBL abbreviations), King James, or Douay-Rheims. A
  convention lists only the names that differ, and an abbreviation is shown
  only where the SBL Handbook gives one for that name.

## Versification

`catalog/scripture/versification/english.tsv`, read by `Versification`
(E28): each book's first chapter and every chapter's verses under the
English (KJV) scheme, counted from eBible.org's public-domain 1769 King
James Version and checked against the World English Bible and STEPBible's
TVTMS. The 66 books have 1,189 chapters and 31,102 verses. Every reference
is checked against it; Hebrew, Greek, and Latin numbering come after 1.0.

## References

- A **passage** is a run of verses in one book, from a first verse to a
  last, checked against the scheme when it is made. A **reading** is one or
  more passages in the plan's order (E30).
- **Plan files** write readings in one strict format: `GEN 1`, `GEN 1-2`,
  `JHN 3:16`, `JHN 3:1-21`, `JHN 3:16-4:3`, joined by `; `. Anything else is
  refused with its reason, including a range written longer than needed
  (`GEN 2-2` is `GEN 2`).
- **Readers see** "John 3:1–21", "Genesis 1–2", "Psalm 23" (one psalm),
  "Psalms 120–122", and "Jude 3–5" or "Jude" (one-chapter books by verse,
  an app convention), in full or abbreviated ("Gen 1–2"), under their
  convention.

## Verse sets

`VerseSet` holds verses, each once, so union, intersection, and difference
give a plan's unique coverage, its repeats, and what it leaves out, and
every chapter it touches is whole or partly covered. Plan completion is
never taken as Bible coverage (P11.4).

## Words and reading time

`catalog/scripture/words/web.tsv`, read by `WordCounts` (E31): the words in
each verse of the 66 books, numbered by the English scheme, counted from
the public-domain World English Bible by `scripts/wordcounts.swift`, whose
header gives the method. The 66 books come to 754,449 words.

`Workload` turns words into minutes at 238 a minute read silently and 183
aloud (Brysbaert, 2019), shown as a rounded range ("About 9–11 minutes.
Estimates vary."). `PlanWorkload` gives a plan's lightest, middle, and
heaviest reading.

## Sources and credit

- eBible.org's King James Version (1769) for the verse counts and World
  English Bible for the word counts, both public domain (the KJV's text is
  under Crown letters patent in the United Kingdom, which does not reach
  its chapter and verse numbers; no text of either is kept).
- USFM 3.0 for ids and common names, and *The SBL Handbook of Style*, 2nd
  edition (2014), for names and abbreviations.
- **STEPBible**: TVTMS, from STEPBible.org's STEPBible-Data, based on work
  at Tyndale House, Cambridge, under CC BY 4.0, checks the English verse
  counts and will give the other schemes. The sources page (P16.5) credits
  it.
- The orders' and names' other sources are listed inside `books.json`.
