# Where a reading opens

Day by Word never shows Bible text (D13). It opens the reader's own Bible:
at launch, YouVersion and Bible.com, and Copy reference everywhere (D26).
Each destination is tested before it is offered, and this file records
what was tested, when, and its limits. Opening a link is never a reading:
the reader marks what they read (docs/product.md, "Marking honestly").

Bible Gateway, ESV.org, Olive Tree, Logos, Blue Letter Bible, and audio
services come after launch (roadmap Phase 19), each tested on a device
first and recorded here.

## YouVersion and Bible.com

One link serves both: a Bible.com address, which opens the YouVersion app
where it is installed and the website otherwise.

    https://www.bible.com/bible/{version}/{BOOK}.{chapter}[.{verses}].{ABBREVIATION}

- `{version}` is Bible.com's number for the reader's chosen translation,
  and `{ABBREVIATION}` its abbreviation (the number decides the
  translation; the abbreviation only makes the address readable).
- `{BOOK}` is the book's USFM id, which Bible.com uses (D29).
- `{verses}` is one verse (`16`), a range (`1-20`), or ranges in the same
  chapter joined by commas (`1-20,26-29`).

The rule, the same in Swift (`BibleLink`, ReadingEngine) and TypeScript
(`bibleLink`, web/src/lib/domain/bible-link.ts), pinned by
`tests/fixtures/bible-links.json`:

1. **A reading within one chapter opens at its verses.** When every
   passage is in the same book and chapter, in order and not overlapping,
   the link is the chapter alone if the reading is that whole chapter
   (`MRK.4`), and otherwise its verses (`MRK.4.1-20`, `MRK.4.1-20,26-29`).
   The link holds the whole reading.
2. **Any other reading opens at its first chapter.** Bible.com has no
   address for a range across chapters or books (`MRK.4.35-5.20` and
   `MRK.1-3` are not found), so a reading such as Matthew 1–3 or Genesis 50;
   Exodus 1 opens at the first passage's first chapter (`MAT.1`, `GEN.50`),
   and Today says so: "Opens at Matthew 1, where this reading begins."
3. **The translation is the reader's choice**, from the list below, made
   when they choose YouVersion as how they read. There is no default: a
   Bible.com address without a version opens John 1 in the site's own
   choice, which is no use, and choosing one for the reader would put one
   translation forward as the norm (AGENTS.md §3). Until one is chosen,
   Today offers Copy reference and says where to choose.

### Limits, said plainly

- **Verse numbers are the common English ones** (the King James numbering
  the catalog uses, docs/scripture.md). A translation that numbers some
  chapters differently (for example the NABRE and Douay-Rheims in Joel,
  Malachi, and the Psalms' titles) can open a little off, or at an empty
  page. Bible.com does not always refuse such an address: Malachi 4 in the
  NABRE answers with an empty page. Settings says so under the
  translation.
- **A reading across chapters opens at its start**, as rule 2 says; the
  reader reads on from there.
- **Nothing comes back.** YouVersion does not tell Day by Word what was
  read, and nothing is synced; the reader marks it (D26).

### Translations

Each was checked on 2026-11-21 by loading `/bible/{version}/JHN.1.{ABBR}`
and `/versions/{version}` on Bible.com: the page's canonical address
carried the same number and abbreviation, and the version page its name.
The list is in alphabetical order of name; no translation is put first.

| Number | Abbreviation | Name |
|---|---|---|
| 12 | ASV | American Standard Version |
| 1588 | AMP | Amplified Bible |
| 3034 | BSB | Berean Standard Bible |
| 1713 | CSB | Christian Standard Bible |
| 37 | CEB | Common English Bible |
| 392 | CEV | Contemporary English Version |
| 55 | DRC1752 | Douay-Rheims Challoner Revision 1752 |
| 59 | ESV | English Standard Version 2025 |
| 68 | GNT | Good News Translation |
| 1 | KJV | King James Version |
| 3345 | LSB | Legacy Standard Bible |
| 463 | NABRE | New American Bible, revised edition |
| 100 | NASB1995 | New American Standard Bible (1995) |
| 2692 | NASB2020 | New American Standard Bible (2020) |
| 107 | NET | New English Translation |
| 111 | NIV | New International Version |
| 114 | NKJV | New King James Version |
| 116 | NLT | New Living Translation |
| 3523 | NRSVUE | New Revised Standard Version, Updated Edition |
| 2020 | RSV | Revised Standard Version |
| 97 | MSG | The Message |
| 206 | WEBUS | World English Bible, American English Edition |

Bible.com titles the WEBUS "World English Bible, American English Edition,
without Strong's Numbers"; the shorter name above is for the picker.
Other translations can be added the same way: check both pages, add a row
here, and add it to both runtimes and the fixture.

### What was tested

- **2026-11-21, Bible.com in a browser** (the website, not the app):
  `MRK.4`, `MRK.4.1-20`, `MRK.4.1-20,26-29`, `PSA.119`, `PSA.119.1-32`,
  `OBA.1` and `JHN.21.25` open the passage named; `MRK.4.35-5.20`,
  `MRK.1-3` and `MRK.4.1-99` are not found (404); `/bible/MRK.4`, with no
  version, opens John 1.
- **2026-11-21, the app link**: Apple's association file for
  `www.bible.com` and `bible.com` (from Apple's CDN,
  `app-site-association.cdn-apple.com`) gives every path (`*`) to the
  YouVersion app (`tv.lifechurch.bible`), so these addresses are universal
  links that open the app where it is installed.
- **2026-11-21, the app in the iOS Simulator** (iOS 27.2, which cannot
  install YouVersion): with the KJV chosen, Open in YouVersion on Gospels
  at your pace's first reading (Matthew 1–3) opened Safari at Bible.com's
  Matthew 1 in the KJV, and Today said "Opens at Matthew 1, where this
  reading begins." Without a translation, Today offered Copy reference and
  a way to Settings to choose one.
- **Not yet tested on a device** (P8.5): an iPhone with YouVersion
  installed, opening a whole chapter, a verse range, a reading across
  chapters, and a translation the app has not downloaded. Record the date,
  the iOS and YouVersion versions, and what each link did.
