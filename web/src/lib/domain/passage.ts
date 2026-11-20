// Passages and readings (docs/decisions.md E30), as Swift's Passage and
// Reading make them: a passage is a run of verses in one book, checked
// against a scheme when it is made; a reading is one or more passages.
import type { BookID } from "./ids.ts";
import {
  comparePlaces,
  place,
  placeText,
  type ChapterVerse,
  type Scheme,
  type Span,
  type Versification,
} from "./versification.ts";

export type PassageErrorKind =
  | "unknownBook"
  | "noSuchChapter"
  | "noSuchVerse"
  | "endsBeforeItStarts"
  | "emptyReading"
  | "mixedSchemes";

export class PassageError extends Error {
  override name = "PassageError";
  readonly kind: PassageErrorKind;
  constructor(kind: PassageErrorKind, message: string) {
    super(message);
    this.kind = kind;
  }
}

export interface Passage {
  readonly scheme: Scheme;
  readonly book: BookID;
  readonly start: ChapterVerse;
  readonly end: ChapterVerse;
}

export interface Reading {
  readonly passages: readonly Passage[];
}

/** The verses from `start` to `end`, inclusive. */
export function versesPassage(
  book: BookID,
  start: ChapterVerse,
  end: ChapterVerse,
  versification: Versification,
): Passage {
  if (!versification.chapters(book)) {
    throw new PassageError("unknownBook", `${book} is not numbered in this scheme`);
  }
  for (const at of [start, end]) {
    const verses = versification.verses(book, at.chapter);
    if (!verses) throw new PassageError("noSuchChapter", `${book} has no chapter ${at.chapter}`);
    if (at.verse < verses.first || at.verse > verses.last) {
      throw new PassageError("noSuchVerse", `${book} has no verse ${placeText(at)}`);
    }
  }
  if (comparePlaces(start, end) > 0) {
    throw new PassageError(
      "endsBeforeItStarts",
      `${book} ${placeText(start)}-${placeText(end)} ends before it starts`,
    );
  }
  return { scheme: versification.scheme, book, start, end };
}

/** Whole chapters, from the first verse of the first to the last verse of the last. */
export function chaptersPassage(
  book: BookID,
  chapters: Span,
  versification: Versification,
): Passage {
  if (!versification.chapters(book)) {
    throw new PassageError("unknownBook", `${book} is not numbered in this scheme`);
  }
  const first = versification.verses(book, chapters.first);
  if (!first) throw new PassageError("noSuchChapter", `${book} has no chapter ${chapters.first}`);
  const last = versification.verses(book, chapters.last);
  if (!last) throw new PassageError("noSuchChapter", `${book} has no chapter ${chapters.last}`);
  return versesPassage(
    book,
    place(chapters.first, first.first),
    place(chapters.last, last.last),
    versification,
  );
}

export function reading(passages: readonly Passage[]): Reading {
  const first = passages[0];
  if (!first) throw new PassageError("emptyReading", "a reading needs at least one passage");
  if (!passages.every((p) => p.scheme === first.scheme)) {
    throw new PassageError(
      "mixedSchemes",
      "a reading's passages must share one versification scheme",
    );
  }
  return { passages };
}

function sameScheme(passage: Passage, versification: Versification): void {
  if (passage.scheme !== versification.scheme) {
    throw new Error("a passage is read under its own scheme");
  }
}

/**
 * Whether the passage begins at the start of its first chapter and ends at
 * the end of its last, so it can be shown as chapters alone.
 */
export function isWholeChapters(passage: Passage, versification: Versification): boolean {
  sameScheme(passage, versification);
  return (
    versification.verses(passage.book, passage.start.chapter)?.first === passage.start.verse &&
    versification.verses(passage.book, passage.end.chapter)?.last === passage.end.verse
  );
}

/** How many verses the passage holds. */
export function passageVerseCount(passage: Passage, versification: Versification): number {
  sameScheme(passage, versification);
  let total = 0;
  for (let chapter = passage.start.chapter; chapter <= passage.end.chapter; chapter += 1) {
    const verses = versification.verses(passage.book, chapter);
    if (!verses) continue;
    const first = chapter === passage.start.chapter ? passage.start.verse : verses.first;
    const last = chapter === passage.end.chapter ? passage.end.verse : verses.last;
    total += last - first + 1;
  }
  return total;
}

/** How many verses the reading holds, counting a repeated verse each time it is given. */
export function readingVerseCount(r: Reading, versification: Versification): number {
  return r.passages.reduce((sum, p) => sum + passageVerseCount(p, versification), 0);
}
