// The chapters and verses of each book under one versification scheme, read
// from catalog/scripture/versification/english.tsv (docs/decisions.md E28),
// as Swift's Versification reads it.
import { isBookID, type BookID } from "./ids.ts";
import { parseSwiftInt } from "./numbers.ts";
import type { BookRegistry } from "./registry.ts";
import { canonBooks } from "./registry.ts";

/** The schemes Day by Word knows; only English is loaded so far. */
export const schemes = ["english"] as const;
export type Scheme = (typeof schemes)[number];

/** A place in a book: a chapter and a verse, written `chapter:verse` on the wire. */
export interface ChapterVerse {
  chapter: number;
  verse: number;
}

export function place(chapter: number, verse: number): ChapterVerse {
  return { chapter, verse };
}

export function placeText(p: ChapterVerse): string {
  return `${p.chapter}:${p.verse}`;
}

export function comparePlaces(a: ChapterVerse, b: ChapterVerse): number {
  return a.chapter - b.chapter || a.verse - b.verse;
}

export function samePlace(a: ChapterVerse, b: ChapterVerse): boolean {
  return a.chapter === b.chapter && a.verse === b.verse;
}

/** An inclusive range of whole numbers. */
export interface Span {
  first: number;
  last: number;
}

export function spanCount(span: Span): number {
  return span.last - span.first + 1;
}

export type VersificationErrorKind =
  "malformedLine" | "duplicateBook" | "unregisteredBook" | "missingBook";

export class VersificationError extends Error {
  override name = "VersificationError";
  readonly kind: VersificationErrorKind;
  constructor(kind: VersificationErrorKind, message: string) {
    super(message);
    this.kind = kind;
  }
}

interface Entry {
  firstChapter: number;
  /** Each chapter's verse numbers. */
  verses: Span[];
  /** The position of each chapter's first verse in the book. */
  starts: number[];
}

export class Versification {
  readonly scheme: Scheme;
  /** The books the scheme numbers, in the file's order. */
  readonly books: BookID[];
  readonly #entries: Map<BookID, Entry>;

  /**
   * Reads a scheme's file: a line per book with its USFM id, its first
   * chapter, and each chapter's verses as a count (`31`) or a range (`4-13`).
   * Lines starting with `#` are comments. Lines end in LF only.
   */
  constructor(scheme: Scheme, tsv: string) {
    const books: BookID[] = [];
    const entries = new Map<BookID, Entry>();
    tsv.split("\n").forEach((line, index) => {
      const number = index + 1;
      if (line === "" || line.startsWith("#")) return;
      const malformed = () =>
        new VersificationError(
          "malformedLine",
          `line ${number} is not a book id, a first chapter, and its chapters' verses`,
        );
      const cells = line.split("\t");
      const book = cells[0] ?? "";
      const first = parseSwiftInt(cells[1] ?? "");
      if (cells.length !== 3 || !isBookID(book) || first === undefined || first < 1) {
        throw malformed();
      }
      if (entries.has(book)) {
        throw new VersificationError("duplicateBook", `${book} is numbered twice`);
      }
      // Unlike the word counts, Swift splits the chapters omitting empty
      // fields, so extra spaces between them are allowed.
      const fields = (cells[2] ?? "").split(" ").filter((field) => field !== "");
      if (fields.length === 0) throw malformed();
      const verses = fields.map((field): Span => {
        const bounds = field.split("-").map(parseSwiftInt);
        const [start, last] = bounds;
        if (bounds.length === 1 && start !== undefined && start >= 1)
          return { first: 1, last: start };
        if (
          bounds.length === 2 &&
          start !== undefined &&
          last !== undefined &&
          1 < start &&
          start <= last
        ) {
          return { first: start, last };
        }
        throw malformed();
      });
      books.push(book);
      const starts = [0];
      for (const span of verses.slice(0, -1)) starts.push((starts.at(-1) ?? 0) + spanCount(span));
      entries.set(book, { firstChapter: first, verses, starts });
    });
    this.scheme = scheme;
    this.books = books;
    this.#entries = entries;
  }

  /** The book's chapter numbers, or undefined if the scheme does not number it. */
  chapters(book: BookID): Span | undefined {
    const entry = this.#entries.get(book);
    return (
      entry && { first: entry.firstChapter, last: entry.firstChapter + entry.verses.length - 1 }
    );
  }

  /** The chapter's verse numbers, or undefined if the scheme has no such chapter. */
  verses(book: BookID, chapter: number): Span | undefined {
    const entry = this.#entries.get(book);
    if (!entry || !Number.isInteger(chapter)) return undefined;
    return entry.verses[chapter - entry.firstChapter];
  }

  contains(book: BookID, at: ChapterVerse): boolean {
    const verses = this.verses(book, at.chapter);
    return verses !== undefined && verses.first <= at.verse && at.verse <= verses.last;
  }

  /** How many verses the scheme gives the book. */
  verseCount(book: BookID): number {
    return this.#entries.get(book)?.verses.reduce((sum, span) => sum + spanCount(span), 0) ?? 0;
  }

  /**
   * The verse's position in its book, counting from 0 at the book's first
   * verse, across chapter ends; undefined if the scheme does not have it.
   */
  position(at: ChapterVerse, book: BookID): number | undefined {
    const entry = this.#entries.get(book);
    const verses = this.verses(book, at.chapter);
    if (!entry || !verses || at.verse < verses.first || at.verse > verses.last) return undefined;
    return (entry.starts[at.chapter - entry.firstChapter] ?? 0) + at.verse - verses.first;
  }

  /** The verse at a position in its book, or undefined past the book's end. */
  placeAt(position: number, book: BookID): ChapterVerse | undefined {
    const entry = this.#entries.get(book);
    if (!entry || position < 0) return undefined;
    let index = -1;
    entry.starts.forEach((start, i) => {
      if (start <= position) index = i;
    });
    const start = entry.starts[index];
    const verses = entry.verses[index];
    if (start === undefined || !verses || position - start >= spanCount(verses)) return undefined;
    return place(entry.firstChapter + index, verses.first + position - start);
  }

  /**
   * Throws unless every book the scheme numbers is registered, and every book
   * a canon lists is numbered.
   */
  check(registry: BookRegistry): void {
    for (const book of this.books) {
      if (!registry.book(book)) {
        throw new VersificationError("unregisteredBook", `${book} is not in the book registry`);
      }
    }
    for (const canon of registry.canons) {
      for (const book of canonBooks(canon)) {
        if (!this.chapters(book)) {
          throw new VersificationError(
            "missingBook",
            `${book}, a book of the ${canon.id} canon, is not numbered`,
          );
        }
      }
    }
  }
}
