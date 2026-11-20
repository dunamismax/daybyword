// A reading as the reader sees it, under their naming convention (D29), as
// Swift's ReferenceFormatter shows it: "John 3:1–21", "Genesis 1–2", "Psalm
// 119:1–24; Psalm 120", "Jude 3–5", or abbreviated "Gen 1–2", with en dashes
// (docs/decisions.md E30).
import type { BookID } from "./ids.ts";
import { isWholeChapters, type Passage, type Reading } from "./passage.ts";
import { bookName, type BookRegistry, type NamingConvention } from "./registry.ts";
import { placeText, samePlace, spanCount, type Versification } from "./versification.ts";

export type FormatStyle = "full" | "abbreviated";

// An en dash, U+2013.
const dash = "–";

export class ReferenceFormatter {
  readonly registry: BookRegistry;
  readonly versification: Versification;
  readonly convention: NamingConvention;

  constructor(
    registry: BookRegistry,
    versification: Versification,
    convention: NamingConvention = "common",
  ) {
    this.registry = registry;
    this.versification = versification;
    this.convention = convention;
  }

  reading(r: Reading, style: FormatStyle = "full"): string {
    return r.passages.map((p) => this.passage(p, style)).join("; ");
  }

  passage(passage: Passage, style: FormatStyle = "full"): string {
    const { start, end } = passage;
    const chapters = this.versification.chapters(passage.book);
    const oneChapterBook = chapters !== undefined && spanCount(chapters) === 1;
    const name = this.#bookName(passage.book, style, start.chapter === end.chapter);
    let range: string | undefined;
    if (isWholeChapters(passage, this.versification)) {
      if (oneChapterBook) range = undefined;
      else if (start.chapter === end.chapter) range = `${start.chapter}`;
      else range = `${start.chapter}${dash}${end.chapter}`;
    } else if (oneChapterBook) {
      range = samePlace(start, end) ? `${start.verse}` : `${start.verse}${dash}${end.verse}`;
    } else if (samePlace(start, end)) {
      range = placeText(start);
    } else if (start.chapter === end.chapter) {
      range = `${placeText(start)}${dash}${end.verse}`;
    } else {
      range = `${placeText(start)}${dash}${placeText(end)}`;
    }
    return range === undefined ? name : `${name} ${range}`;
  }

  #bookName(id: BookID, style: FormatStyle, onePsalm: boolean): string {
    const book = this.registry.book(id);
    if (!book) return id;
    const names = bookName(book, this.convention);
    if (style === "abbreviated") return names.abbreviation ?? names.name;
    return id === "PSA" && onePsalm && names.name === "Psalms" ? "Psalm" : names.name;
  }
}
