// The one strict way plan files write a reading (docs/decisions.md E30), as
// Swift's ReferenceFormat reads and writes it: passages joined by `; `, each
// a USFM book id, a space, and `1`, `1-2`, `3:16`, `3:1-21` or `3:16-4:3`.
import { isBookID } from "./ids.ts";
import {
  chaptersPassage,
  isWholeChapters,
  PassageError,
  reading as makeReading,
  versesPassage,
  type Passage,
  type PassageErrorKind,
  type Reading,
} from "./passage.ts";
import { place, placeText, samePlace, type Versification } from "./versification.ts";

export type ReferenceFormatErrorKind =
  "empty" | "malformed" | "notABook" | "redundant" | PassageErrorKind;

/**
 * Why plan-file text is not a reading. A passage the scheme lacks keeps the
 * passage error's kind (`noSuchVerse`, …); the message is Swift's wording.
 */
export class ReferenceFormatError extends Error {
  override name = "ReferenceFormatError";
  readonly kind: ReferenceFormatErrorKind;
  constructor(kind: ReferenceFormatErrorKind, message: string) {
    super(message);
    this.kind = kind;
  }
}

const emptyMessage = 'a reading is missing, or has an empty passage between "; " separators';

function malformed(text: string): ReferenceFormatError {
  return new ReferenceFormatError(
    "malformed",
    `"${text}" is not written as BOOK 1, BOOK 1-2, BOOK 1:2, BOOK 1:2-3, or BOOK 1:2-3:4`,
  );
}

function passageFailure(error: unknown): never {
  if (error instanceof PassageError) throw new ReferenceFormatError(error.kind, error.message);
  throw error;
}

/** Reads a reading, throwing the first problem found. */
export function parseReading(text: string, versification: Versification): Reading {
  if (text === "") throw new ReferenceFormatError("empty", emptyMessage);
  const passages = text.split("; ").map((part) => parsePassage(part, versification));
  try {
    return makeReading(passages);
  } catch (error) {
    passageFailure(error);
  }
}

type Side =
  { kind: "chapter"; chapter: number } | { kind: "verse"; chapter: number; verse: number };

/** A chapter or verse number: one to three ASCII digits, the first not zero. */
function number(text: string): number | undefined {
  return /^[1-9][0-9]{0,2}$/.test(text) ? Number(text) : undefined;
}

function side(text: string): Side | undefined {
  const numbers = text.split(":").map(number);
  const [chapter, verse] = numbers;
  if (numbers.length === 1 && chapter !== undefined) return { kind: "chapter", chapter };
  if (numbers.length === 2 && chapter !== undefined && verse !== undefined) {
    return { kind: "verse", chapter, verse };
  }
  return undefined;
}

export function parsePassage(text: string, versification: Versification): Passage {
  if (text === "") throw new ReferenceFormatError("empty", emptyMessage);
  const words = text.split(" ");
  const [bookText, rangeText] = words;
  if (words.length !== 2 || bookText === undefined || rangeText === undefined)
    throw malformed(text);
  if (!isBookID(bookText)) {
    throw new ReferenceFormatError("notABook", `"${bookText}" is not a USFM book id`);
  }
  const book = bookText;
  const written = rangeText.split("-");
  const sides = written.map(side);
  if (written.length < 1 || written.length > 2 || sides.some((s) => s === undefined)) {
    throw malformed(text);
  }
  const shorter = (range: string) =>
    new ReferenceFormatError("redundant", `"${text}" should be written "${book} ${range}"`);

  const [a, b] = sides as [Side, Side | undefined];
  try {
    if (a.kind === "chapter" && b === undefined) {
      return chaptersPassage(book, { first: a.chapter, last: a.chapter }, versification);
    }
    if (a.kind === "verse" && b === undefined) {
      const at = place(a.chapter, a.verse);
      return versesPassage(book, at, at, versification);
    }
    if (a.kind === "chapter" && b?.kind === "chapter") {
      if (a.chapter === b.chapter) throw shorter(`${a.chapter}`);
      if (a.chapter > b.chapter) {
        throw new PassageError(
          "endsBeforeItStarts",
          `${book} ${a.chapter}:1-${b.chapter}:1 ends before it starts`,
        );
      }
      return chaptersPassage(book, { first: a.chapter, last: b.chapter }, versification);
    }
    if (a.kind === "verse" && b?.kind === "chapter") {
      // After the hyphen in `JHN 3:1-21`, a lone number is the last verse.
      if (a.verse === b.chapter) throw shorter(`${a.chapter}:${a.verse}`);
      return versesPassage(
        book,
        place(a.chapter, a.verse),
        place(a.chapter, b.chapter),
        versification,
      );
    }
    if (a.kind === "verse" && b?.kind === "verse") {
      if (a.chapter === b.chapter) {
        throw shorter(
          a.verse === b.verse ? `${a.chapter}:${a.verse}` : `${a.chapter}:${a.verse}-${b.verse}`,
        );
      }
      return versesPassage(
        book,
        place(a.chapter, a.verse),
        place(b.chapter, b.verse),
        versification,
      );
    }
    // A chapter, then a verse: `GEN 1-2:3`.
    throw malformed(text);
  } catch (error) {
    if (error instanceof ReferenceFormatError) throw error;
    passageFailure(error);
  }
}

/** The shortest plan-file writing of a passage: whole chapters are written as chapters. */
export function passageText(passage: Passage, versification: Versification): string {
  const { start, end } = passage;
  let range: string;
  if (isWholeChapters(passage, versification)) {
    range = start.chapter === end.chapter ? `${start.chapter}` : `${start.chapter}-${end.chapter}`;
  } else if (samePlace(start, end)) {
    range = placeText(start);
  } else if (start.chapter === end.chapter) {
    range = `${placeText(start)}-${end.verse}`;
  } else {
    range = `${placeText(start)}-${placeText(end)}`;
  }
  return `${passage.book} ${range}`;
}

/** The shortest plan-file writing of a reading, which reads back as the same reading. */
export function readingText(r: Reading, versification: Versification): string {
  return r.passages.map((p) => passageText(p, versification)).join("; ");
}
