// The words in each verse, numbered by a scheme and read from
// catalog/scripture/words/web.tsv (docs/decisions.md E31), as Swift's
// WordCounts reads them. Numbers only, for workload estimates (D13).
import { isBookID, type BookID } from "./ids.ts";
import { parseSwiftInt } from "./numbers.ts";
import type { Passage, Reading } from "./passage.ts";
import type { Scheme, Versification } from "./versification.ts";
import { spanCount } from "./versification.ts";

export type WordCountsErrorKind =
  "malformedLine" | "noSuchChapter" | "wrongVerseCount" | "duplicateChapter" | "missingChapter";

export class WordCountsError extends Error {
  override name = "WordCountsError";
  readonly kind: WordCountsErrorKind;
  constructor(kind: WordCountsErrorKind, message: string) {
    super(message);
    this.kind = kind;
  }
}

export class WordCounts {
  readonly scheme: Scheme;
  /** The books counted, in the file's order. */
  readonly books: BookID[];
  /** For each book, the words before each verse position, with the book's total last. */
  readonly #runningTotals: Map<BookID, number[]>;
  readonly #versification: Versification;

  /**
   * Reads a file of a line per chapter: the book's id, the chapter, and each
   * verse's words. Every chapter of a counted book must be there, with a
   * count for each verse. Lines starting with `#` are comments; LF only.
   */
  constructor(tsv: string, versification: Versification) {
    const books: BookID[] = [];
    const chapters = new Map<BookID, Map<number, number[]>>();
    tsv.split("\n").forEach((line, index) => {
      const number = index + 1;
      if (line === "" || line.startsWith("#")) return;
      const malformed = () =>
        new WordCountsError(
          "malformedLine",
          `line ${number} is not a book id, a chapter, and its verses' word counts`,
        );
      const cells = line.split("\t");
      const book = cells[0] ?? "";
      const chapter = parseSwiftInt(cells[1] ?? "");
      if (cells.length !== 3 || !isBookID(book) || chapter === undefined) throw malformed();
      const words = (cells[2] ?? "").split(" ").map(parseSwiftInt);
      if (words.length === 0 || !words.every((w) => w !== undefined && w >= 0)) throw malformed();
      const verses = versification.verses(book, chapter);
      if (!verses) {
        throw new WordCountsError(
          "noSuchChapter",
          `${book} ${chapter} is not a chapter of the scheme`,
        );
      }
      if (words.length !== spanCount(verses)) {
        throw new WordCountsError(
          "wrongVerseCount",
          `${book} ${chapter} has ${spanCount(verses)} verses in the scheme but ${words.length} counts`,
        );
      }
      let counted = chapters.get(book);
      if (!counted) {
        books.push(book);
        counted = new Map();
        chapters.set(book, counted);
      }
      if (counted.has(chapter)) {
        throw new WordCountsError("duplicateChapter", `${book} ${chapter} is counted twice`);
      }
      counted.set(chapter, words as number[]);
    });
    const totals = new Map<BookID, number[]>();
    for (const book of books) {
      const running = [0];
      const range = versification.chapters(book);
      for (let chapter = range?.first ?? 1; range && chapter <= range.last; chapter += 1) {
        const words = chapters.get(book)?.get(chapter);
        if (!words) {
          throw new WordCountsError("missingChapter", `${book} ${chapter} is not counted`);
        }
        for (const count of words) running.push((running.at(-1) ?? 0) + count);
      }
      totals.set(book, running);
    }
    this.scheme = versification.scheme;
    this.books = books;
    this.#runningTotals = totals;
    this.#versification = versification;
  }

  /** The words in a passage, or undefined if its book is not counted. */
  wordsInPassage(passage: Passage): number | undefined {
    if (passage.scheme !== this.scheme)
      throw new Error("a passage is counted under its own scheme");
    const totals = this.#runningTotals.get(passage.book);
    if (!totals) return undefined;
    const first = this.#versification.position(passage.start, passage.book) ?? 0;
    const last = this.#versification.position(passage.end, passage.book) ?? 0;
    return (totals[last + 1] ?? 0) - (totals[first] ?? 0);
  }

  /** The words in a reading, counting a repeated passage each time, or undefined if a book is not counted. */
  wordsInReading(r: Reading): number | undefined {
    let total = 0;
    for (const passage of r.passages) {
      const words = this.wordsInPassage(passage);
      if (words === undefined) return undefined;
      total += words;
    }
    return total;
  }

  /** The words in a book, or undefined if it is not counted. */
  wordsOfBook(book: BookID): number | undefined {
    return this.#runningTotals.get(book)?.at(-1);
  }
}
