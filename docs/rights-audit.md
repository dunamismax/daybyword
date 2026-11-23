# Rights audit

*Generated from `catalog/SOURCES.md` and `catalog/plans/` by
`scripts/rights-audit.swift` (BUILD.md P18.1). Do not edit: change the
sources or the plans and run `make rights-audit`. `make check` fails if
this file is stale, or if anything served is not cleared everywhere.*

Version 1.0 serves the US App Store (D16) and daybyword.com, which
reaches readers everywhere, so every plan it serves and every source
whose data ships must be `cleared` everywhere. The catalog compiler
also refuses, in release mode, any plan whose source is not cleared
(P4.3).

## The plans served

| Plan | Review | Source | Status | Territories |
|---|---|---|---|---|
| The Bible in a year, five days a week (`bible-in-a-year-five-days`) | reviewed | `daybyword-original` | cleared | everywhere. |
| The Bible in a year (`bible-in-a-year`) | reviewed | `daybyword-original` | cleared | everywhere. |
| Gospels at your pace (`gospels-at-your-pace`) | reviewed | `daybyword-original` | cleared | everywhere. |
| The New Testament in a year, five days a week (`new-testament-in-a-year-five-days`) | reviewed | `daybyword-original` | cleared | everywhere. |
| Paul's letters (`pauls-letters`) | reviewed | `daybyword-original` | cleared | everywhere. |
| Proverbs through the month (`proverbs-through-the-month`) | reviewed | `daybyword-original` | cleared | everywhere. |
| A psalm a day (`psalm-a-day`) | reviewed | `daybyword-original` | cleared | everywhere. |
| The Story of Scripture (`story-of-scripture`) | reviewed | `daybyword-original` | cleared | everywhere. |

## The sources

| Source | Status | Used for | Basis | Credit | Territories |
|---|---|---|---|---|---|
| Day by Word's own plans (`daybyword-original`) | cleared | the plans Day by Word makes itself, labeled as original: Gospels at your pace, the Bible in a year, Proverbs through the month, the Bible in a year five days a week, the New Testament in a year five days a week, A psalm a day, Paul's letters, the Story of Scripture, and the rest of the launch catalog (BUILD.md D14, D39). | original work. | none. | everywhere. |
| King James Version, 1769 text, with Apocrypha (eBible.org) (`kjv-1769-ebible`) | cleared: for chapter and verse counts | `scripture/versification/english.tsv`, the English (KJV) scheme's chapter and verse counts, counted by `scripts/versification.swift` (BUILD.md P3.2a). Only numbers are kept; no text is stored or shown (D13). | eBible.org's copyright page for the edition says "Public Domain" and notes that letters patent restrict printing the text in the United Kingdom. Chapter and verse numbers are facts about the text's divisions, not the text, so the patent does not reach them; and nothing of the text ships. | none required. Credited on the sources page (P16.5) as the source of the English counts. | everywhere, for the counts. |
| World English Bible (eBible.org) (`web-ebible`) | cleared: for word counts; `reference` for chapter and verse counts | `scripture/words/web.tsv`, the words in each verse of the 66 books, numbered by the English scheme, counted by `scripts/wordcounts.swift` for workload estimates (BUILD.md P3.6, docs/decisions.md E31). Only numbers are kept; no text is stored or shown (D13). Also a second, independent check of the English counts. Every difference is listed by `swift scripts/versification.swift compare`: in the 66 books only Romans 14 and 16, where the WEB prints the closing doxology (KJV Romans 16:25–27) at the end of chapter 14, a placement TVTMS records as "PassageMoved"; in the Apocrypha, Sirach 33 (31 verses in the KJV, 33 in the WEB, as TVTMS records for KJV and NRSV), Esther (the WEB prints the whole Greek Esther, the KJV only the Rest of Esther from 10:4), and Daniel's additions (which the WEB prints inside its Greek Daniel). | eBible.org's copyright page in the download (`copr.htm`) says "The World English Bible is in the Public Domain. That means that it is not copyrighted," and that "World English Bible" is a trademark of eBible.org, which Day by Word does not use for anything of its own. Word counts are facts about the text, and nothing of the text ships. | none required. Credited on the sources page (P16.5) as the source of the workload estimates. | everywhere. |
| STEPBible-Data, TVTMS (`stepbible-tvtms`) | cleared: under CC BY 4.0, with attribution | so far, a check of the English counts: all 243 of its "chapter ends at verse N" tests in the English column for registered books agree with the KJV counts except one, Mark 16, whose test describes Bibles that end at 16:8, not the KJV. The Hebrew, Greek, and Latin mappings will be derived from it after 1.0 (P3.2b). | the repository's README and the file's own header state CC BY 4.0: any part may be included in software or publications without asking, and the data may be reformatted. The header asks users not to redistribute the file itself and to note any changes; Day by Word never commits or serves the file, only data derived from it, and records its changes in `docs/scripture.md`. Research finding 5's older Tyndale House pages with non-commercial terms do not apply to this file, whose name and header both say CC BY. | credit "STEP Bible", linked to <https://www.STEPBible.org>, on the sources page (P16.5) and in `docs/scripture.md`. | everywhere. |

## Verdict

Every plan served (8) and every cleared source is cleared everywhere: version 1.0 may serve them in the US App Store and on the web. Other storefronts (P18.8) need no further review for these sources, which hold everywhere; new plans need their own entries.
