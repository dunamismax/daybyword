// A reference as it is shown ("Mark 4:1–20") and as a screen reader reads it
// ("Mark, chapter 4, verses 1 to 20"). The domain module formats the display
// (docs/engine.md); pages only show them.
import {
  bookName,
  CivilDateError,
  isWholeChapters,
  parseCivilDate,
  spanCount,
  type Passage,
  type Reading,
  type ReferenceFormatter,
} from "#lib/domain/index.ts";
import { text } from "./strings.ts";

export interface Reference {
  display: string;
  spoken: string;
}

/** The book and the place, so "4:1–20" can be kept on one line. */
export function splitReference(display: string): { book: string; place: string } {
  const space = display.lastIndexOf(" ");
  return space < 0
    ? { book: display, place: "" }
    : { book: display.slice(0, space + 1), place: display.slice(space + 1) };
}

/**
 * A week's start as the address gives it, kept only when it is a date
 * written `YYYY-MM-DD`; anything else, including a date the calendar does
 * not have, is ignored (docs/urls.md).
 */
export function startDate(value: string | null): string | undefined {
  if (value === null) return undefined;
  try {
    parseCivilDate(value);
  } catch (error) {
    if (error instanceof CivilDateError) return undefined;
    throw error;
  }
  return value;
}

/**
 * A passage as a screen reader should say it: "Mark, chapter 4, verses 1 to
 * 20", "Matthew, chapters 1 to 3", "Psalm 23", "Jude". The words come from
 * the string table; the names from the formatter's convention.
 */
export function spokenPassage(passage: Passage, formatter: ReferenceFormatter): string {
  const { start, end } = passage;
  const known = formatter.registry.book(passage.book);
  const book = known ? bookName(known, formatter.convention).name : passage.book;
  const chapters = formatter.versification.chapters(passage.book);
  const oneChapterBook = chapters !== undefined && spanCount(chapters) === 1;
  const values = {
    book,
    chapter: String(start.chapter),
    verse: String(start.verse),
  };
  if (isWholeChapters(passage, formatter.versification)) {
    if (oneChapterBook) return book;
    const last = String(end.chapter);
    if (passage.book === "PSA" && book === "Psalms") {
      return start.chapter === end.chapter
        ? text("reference.psalm", values)
        : text("reference.psalms", { ...values, last });
    }
    return start.chapter === end.chapter
      ? text("reference.chapter", values)
      : text("reference.chapters", { ...values, last });
  }
  if (start.chapter !== end.chapter) {
    return text("reference.across", {
      ...values,
      last: String(end.chapter),
      final: String(end.verse),
    });
  }
  const one = start.verse === end.verse;
  const last = String(end.verse);
  if (oneChapterBook) {
    return one
      ? text("reference.book-verse", values)
      : text("reference.book-verses", { ...values, last });
  }
  return one ? text("reference.verse", values) : text("reference.verses", { ...values, last });
}

/** A reading as it is shown and as it is said. */
export function referenceOf(reading: Reading, formatter: ReferenceFormatter): Reference {
  return {
    display: formatter.reading(reading),
    spoken: reading.passages
      .map((passage) => spokenPassage(passage, formatter))
      .reduce((first, next) => text("reference.then", { first, next })),
  };
}
