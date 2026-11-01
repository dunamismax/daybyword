# Sources and permissions

Every source the catalog uses or consults has an entry here, with the
evidence for its status (AGENTS.md §6, BUILD.md D21). Nothing is served
unless its entry is `cleared` for the readers it reaches, and every plan
file names its entry as its `rights` (docs/catalog-format.md).

The book registry, `scripture/books.json`, lists its own sources (book ids,
names, abbreviations, canons, and orders) inside the file, each with the
date it was checked (docs/decisions.md E27). Those are facts about printed
Bibles, cited, and nothing is copied from them beyond names and orders.

## The schema

Each entry is a `## id: title` heading, where the id is lowercase letters,
digits, and hyphens, followed by these fields in this order. A field that
does not apply says so rather than being left out.

- **Status:** one of `cleared` (may be used as described), `pending` (being
  checked), `rejected` (may not be used), or `reference` (consulted to check
  other sources; nothing from it ships). A source cleared for one use and
  consulted for another says both, the status that governs what ships first.
- **Edition:** the exact edition, printing, or version used.
- **Creator or owner:** who made it, or holds its rights.
- **Used for:** what Day by Word takes from it, and where that lives.
- **Obtained:** where and when it was obtained, with a checksum for a
  download.
- **Basis:** public domain, a licence, or a permission, with the evidence:
  what the title or copyright page, the licence, or the letter says.
- **Attribution:** the credit line required, if any, and where it appears.
- **Territories:** where the basis holds.
- **Checked:** what was checked, and the date.

The catalog compiler reads each entry's id from its heading and its status
from the first word in backticks on its Status line, refuses a plan whose
`rights` names no entry, and in release mode refuses one whose entry is not
`cleared` (BUILD.md P4.3).

---

## daybyword-original: Day by Word's own plans

- **Status:** `cleared`.
- **Edition:** each plan's own version, recorded in its plan file.
- **Creator or owner:** Day by Word (the owner); all rights reserved (D4).
- **Used for:** the plans Day by Word makes itself, labeled as original:
  Gospels at your pace, the Bible in a year, Proverbs through the month, and
  the rest of the launch catalog (BUILD.md D14, D39).
- **Obtained:** written in this repository, from the English versification
  (`kjv-1769-ebible`) and the word counts (`web-ebible`) under rules each
  plan file states. No contemporary publisher's version of a familiar plan
  is used or consulted (AGENTS.md §6).
- **Basis:** original work.
- **Attribution:** none.
- **Territories:** everywhere.
- **Checked:** each plan is reviewed under `docs/editorial.md` before
  release, and its review status is in its plan file.

## kjv-1769-ebible: King James Version, 1769 text, with Apocrypha (eBible.org)

- **Status:** `cleared` for chapter and verse counts.
- **Edition:** the 1769 Oxford text as eBible.org transcribes it, source
  files dated 2026-09-26.
- **Creator or owner:** the text is in the public domain; the transcription
  is eBible.org's.
- **Used for:** `scripture/versification/english.tsv`, the English (KJV)
  scheme's chapter and verse counts, counted by `scripts/versification.swift`
  (BUILD.md P3.2a). Only numbers are kept; no text is stored or shown (D13).
- **Obtained:** <https://ebible.org/Scriptures/eng-kjv_usfm.zip>,
  downloaded 2026-11-01 (SHA-256 `206085ac…efd129`), kept in the gitignored
  `research/ebible/`.
- **Basis:** eBible.org's copyright page for the edition says "Public
  Domain" and notes that letters patent restrict printing the text in the
  United Kingdom. Chapter and verse numbers are facts about the text's
  divisions, not the text, so the patent does not reach them; and nothing
  of the text ships.
- **Attribution:** none required. Credited on the sources page (P16.5) as
  the source of the English counts.
- **Territories:** everywhere, for the counts.
- **Checked:** the copyright page and the counts against two independent
  sources (`web-ebible`, `stepbible-tvtms`), 2026-11-01.

## web-ebible: World English Bible (eBible.org)

- **Status:** `cleared` for word counts; `reference` for chapter and verse
  counts.
- **Edition:** the World English Bible dated 2024-01-15 in its `\id` lines,
  with the full ecumenical book set.
- **Creator or owner:** the text is in the public domain; "World English
  Bible" is a trademark of eBible.org.
- **Used for:** `scripture/words/web.tsv`, the words in each verse of the 66
  books, numbered by the English scheme, counted by
  `scripts/wordcounts.swift` for workload estimates (BUILD.md P3.6,
  docs/decisions.md E31). Only numbers are kept; no text is stored or shown
  (D13). Also a second, independent check of the English counts. Every
  difference is listed by `swift scripts/versification.swift compare`: in
  the 66 books only Romans 14 and 16, where the WEB prints the closing
  doxology (KJV Romans 16:25–27) at the end of chapter 14, a placement TVTMS
  records as "PassageMoved"; in the Apocrypha, Sirach 33 (31 verses in the
  KJV, 33 in the WEB, as TVTMS records for KJV and NRSV), Esther (the WEB
  prints the whole Greek Esther, the KJV only the Rest of Esther from 10:4),
  and Daniel's additions (which the WEB prints inside its Greek Daniel).
- **Obtained:** <https://ebible.org/Scriptures/eng-web_usfm.zip>, downloaded
  2026-11-01 (SHA-256 `05b0440b…3589c8`), kept in the gitignored
  `research/ebible/`.
- **Basis:** eBible.org's copyright page in the download (`copr.htm`) says
  "The World English Bible is in the Public Domain. That means that it is
  not copyrighted," and that "World English Bible" is a trademark of
  eBible.org, which Day by Word does not use for anything of its own. Word
  counts are facts about the text, and nothing of the text ships.
- **Attribution:** none required. Credited on the sources page (P16.5) as
  the source of the workload estimates.
- **Territories:** everywhere.
- **Checked:** the copyright page, and the counts against the English
  scheme verse by verse, 2026-11-01.

## stepbible-tvtms: STEPBible-Data, TVTMS

- **Status:** `cleared` under CC BY 4.0, with attribution.
- **Edition:** "TVTMS - Translators Versification Traditions with
  Methodology for Standardisation for Eng+Heb+Lat+Grk+Others", at commit
  `1f342173b881ba5d1a5a4cae6e7c6c3fcc7cac51` (2026-07-17).
- **Creator or owner:** STEPBible.org, based on work at Tyndale House,
  Cambridge.
- **Used for:** so far, a check of the English counts: all 243 of its
  "chapter ends at verse N" tests in the English column for registered books
  agree with the KJV counts except one, Mark 16, whose test describes Bibles
  that end at 16:8, not the KJV. The Hebrew, Greek, and Latin mappings will
  be derived from it after 1.0 (P3.2b).
- **Obtained:** <https://github.com/STEPBible/STEPBible-Data>, file
  `Versification/TVTMS - … - STEPBible.org CC BY.txt`, downloaded
  2026-11-01 (SHA-256 `63058e0f…b9ddf8`), kept in `research/stepbible/`.
- **Basis:** the repository's README and the file's own header state CC BY
  4.0: any part may be included in software or publications without asking,
  and the data may be reformatted. The header asks users not to redistribute
  the file itself and to note any changes; Day by Word never commits or
  serves the file, only data derived from it, and records its changes in
  `docs/scripture.md`. Research finding 5's older Tyndale House pages with
  non-commercial terms do not apply to this file, whose name and header
  both say CC BY.
- **Attribution:** credit "STEP Bible", linked to
  <https://www.STEPBible.org>, on the sources page (P16.5) and in
  `docs/scripture.md`.
- **Territories:** everywhere.
- **Checked:** the licence in the README and the file header, 2026-11-01.
