# Sources and permissions

Every source the catalog uses or consults has an entry here, with the
evidence for its status (AGENTS.md §6, BUILD.md D21). Nothing is served
unless its entry is `cleared` for the readers it reaches.

This is the registry's first form. BUILD.md P4.1 gives it its full schema
(territories, commercial, adaptation, offline, print and export rights, AI
use) and the **Wanted** section; until then each entry records what was
checked.

Statuses: `cleared` (may be used as described), `pending` (being checked),
`rejected` (may not be used), `wanted` (not yet obtained), `reference`
(consulted to check other sources; nothing from it ships).

The book registry, `scripture/books.json`, lists its own sources (book ids,
names, abbreviations, canons, and orders) inside the file, each with the
date it was checked (docs/decisions.md E27). Those are facts about printed
Bibles, cited, and nothing is copied from them beyond names and orders.

---

## kjv-1769-ebible: King James Version, 1769 text, with Apocrypha (eBible.org)

- **Status:** `cleared` for chapter and verse counts, everywhere.
- **Used for:** `scripture/versification/english.tsv`, the English (KJV)
  scheme's chapter and verse counts, counted by `scripts/versification.swift`
  (BUILD.md P3.2a). Only numbers are kept; no text is stored or shown (D13).
- **Obtained:** <https://ebible.org/Scriptures/eng-kjv_usfm.zip>, source
  files dated 2026-09-26, downloaded 2026-11-01 (SHA-256
  `206085ac…efd129`), kept in the gitignored `research/ebible/`.
- **Basis:** eBible.org's copyright page for the edition says "Public
  Domain" and notes that letters patent restrict printing the text in the
  United Kingdom. Chapter and verse numbers are facts about the text's
  divisions, not the text, so the patent does not reach them; and nothing
  of the text ships.
- **Attribution:** none required. Credited on the sources page as the
  source of the English counts.
- **Checked:** 2026-11-01.

## web-ebible: World English Bible (eBible.org)

- **Status:** `reference`.
- **Used for:** a second, independent check of the English counts. Every
  difference is listed by `swift scripts/versification.swift compare`: in
  the 66 books only Romans 14 and 16, where the WEB prints the closing
  doxology (KJV Romans 16:25–27) at the end of chapter 14, a placement TVTMS
  records as "PassageMoved"; in the Apocrypha, Sirach 33 (31 verses in the
  KJV, 33 in the WEB, as TVTMS records for KJV and NRSV), Esther (the WEB
  prints the whole Greek Esther, the KJV only the Rest of Esther from 10:4),
  and Daniel's additions (which the WEB prints inside its Greek Daniel).
- **Obtained:** <https://ebible.org/Scriptures/eng-web_usfm.zip>, downloaded
  2026-11-01 (SHA-256 `05b0440b…3589c8`).
- **Basis:** eBible.org states the World English Bible is in the public
  domain; "World English Bible" is its trademark, which Day by Word does not
  use for anything of its own.
- **Checked:** 2026-11-01.

## stepbible-tvtms: STEPBible-Data, TVTMS

- **Title:** "TVTMS - Translators Versification Traditions with Methodology
  for Standardisation for Eng+Heb+Lat+Grk+Others", STEPBible.org, based on
  work at Tyndale House, Cambridge.
- **Status:** `cleared` under CC BY 4.0, with attribution.
- **Used for:** so far, a check of the English counts: all 243 of its
  "chapter ends at verse N" tests in the English column for registered books
  agree with the KJV counts except one, Mark 16, whose test describes Bibles
  that end at 16:8, not the KJV. BUILD.md P3.2b derives the Hebrew, Greek,
  and Latin mappings from it.
- **Obtained:** <https://github.com/STEPBible/STEPBible-Data>, file
  `Versification/TVTMS - … - STEPBible.org CC BY.txt` at commit
  `1f342173b881ba5d1a5a4cae6e7c6c3fcc7cac51` (2026-07-17), downloaded
  2026-11-01 (SHA-256 `63058e0f…b9ddf8`), kept in `research/stepbible/`.
- **Basis:** the repository's README and the file's own header state CC BY
  4.0: any part may be included in software or publications without asking,
  and the data may be reformatted. The header asks users not to redistribute
  the file itself and to note any changes; Day by Word never commits or
  serves the file, only data derived from it, and records its changes in
  `docs/scripture.md` (P3.9). Research finding 5's older Tyndale House pages
  with non-commercial terms do not apply to this file, whose name and header
  both say CC BY.
- **Attribution required:** credit "STEP Bible", linked to
  <https://www.STEPBible.org>, on the sources page (P16.5) and in
  `docs/scripture.md`.
- **Checked:** 2026-11-01.
