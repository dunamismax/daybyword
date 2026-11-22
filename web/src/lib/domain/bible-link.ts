// Where a reading opens in YouVersion and on Bible.com (D26,
// docs/destinations.md), as Swift's BibleLink makes it: one Bible.com
// address, which opens the YouVersion app where it is installed and the
// website otherwise. Opening it is never a reading; the reader marks it.
import type { BookID } from "./ids.ts";
import { isWholeChapters, type Reading } from "./passage.ts";
import type { Versification } from "./versification.ts";

/** A translation on Bible.com, by the number its addresses use. */
export interface BibleTranslation {
  /** Bible.com's version number, which decides the translation. */
  readonly id: number;
  readonly abbreviation: string;
  readonly name: string;
}

/**
 * The translations Day by Word links to, in alphabetical order of name, each
 * checked on Bible.com (docs/destinations.md). The reader chooses one; there
 * is no default.
 */
export const bibleTranslations: readonly BibleTranslation[] = [
  { id: 12, abbreviation: "ASV", name: "American Standard Version" },
  { id: 1588, abbreviation: "AMP", name: "Amplified Bible" },
  { id: 3034, abbreviation: "BSB", name: "Berean Standard Bible" },
  { id: 1713, abbreviation: "CSB", name: "Christian Standard Bible" },
  { id: 37, abbreviation: "CEB", name: "Common English Bible" },
  { id: 392, abbreviation: "CEV", name: "Contemporary English Version" },
  { id: 55, abbreviation: "DRC1752", name: "Douay-Rheims Challoner Revision 1752" },
  { id: 59, abbreviation: "ESV", name: "English Standard Version 2025" },
  { id: 68, abbreviation: "GNT", name: "Good News Translation" },
  { id: 1, abbreviation: "KJV", name: "King James Version" },
  { id: 3345, abbreviation: "LSB", name: "Legacy Standard Bible" },
  { id: 463, abbreviation: "NABRE", name: "New American Bible, revised edition" },
  { id: 100, abbreviation: "NASB1995", name: "New American Standard Bible (1995)" },
  { id: 2692, abbreviation: "NASB2020", name: "New American Standard Bible (2020)" },
  { id: 107, abbreviation: "NET", name: "New English Translation" },
  { id: 111, abbreviation: "NIV", name: "New International Version" },
  { id: 114, abbreviation: "NKJV", name: "New King James Version" },
  { id: 116, abbreviation: "NLT", name: "New Living Translation" },
  { id: 3523, abbreviation: "NRSVUE", name: "New Revised Standard Version, Updated Edition" },
  { id: 2020, abbreviation: "RSV", name: "Revised Standard Version" },
  { id: 97, abbreviation: "MSG", name: "The Message" },
  { id: 206, abbreviation: "WEBUS", name: "World English Bible, American English Edition" },
];

/** The translation with Bible.com's number `id`, if Day by Word links to it. */
export function bibleTranslation(id: number): BibleTranslation | undefined {
  return bibleTranslations.find((t) => t.id === id);
}

export interface BibleLink {
  /** The Bible.com address. */
  readonly address: string;
  /** Whether the address holds the whole reading; when not, it opens at `book` and `chapter`. */
  readonly isWholeReading: boolean;
  readonly book: BookID;
  readonly chapter: number;
}

/**
 * The link for `r` in `translation`: its verses when they lie in one
 * chapter, and otherwise its first chapter, since Bible.com has no address
 * for a range across chapters or books.
 */
export function bibleLink(
  r: Reading,
  translation: BibleTranslation,
  versification: Versification,
): BibleLink {
  const first = r.passages[0];
  if (!first) throw new RangeError("a reading has at least one passage");
  const chapter = first.start.chapter;
  const suffix = `.${translation.abbreviation}`;
  const base = `https://www.bible.com/bible/${translation.id}/${first.book}.${chapter}`;
  // Every passage in the first one's chapter, in order, none overlapping.
  const inOneChapter = r.passages.every(
    (p) => p.book === first.book && p.start.chapter === chapter && p.end.chapter === chapter,
  );
  const inOrder = r.passages.every((p, i) => {
    const previous = r.passages[i - 1];
    return !previous || previous.end.verse < p.start.verse;
  });
  if (!inOneChapter || !inOrder) {
    return { address: base + suffix, isWholeReading: false, book: first.book, chapter };
  }
  if (r.passages.length === 1 && isWholeChapters(first, versification)) {
    return { address: base + suffix, isWholeReading: true, book: first.book, chapter };
  }
  const verses = r.passages.map((p) =>
    p.start.verse === p.end.verse ? `${p.start.verse}` : `${p.start.verse}-${p.end.verse}`,
  );
  return {
    address: `${base}.${verses.join(",")}${suffix}`,
    isWholeReading: true,
    book: first.book,
    chapter,
  };
}
