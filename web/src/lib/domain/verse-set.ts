// A set of verses under one scheme, each counted once (P3.5), as Swift's
// VerseSet keeps it: each book's verses as sorted, separate runs of
// positions, so union, intersection and difference give unique coverage,
// repeats and omissions.
import type { BookID } from "./ids.ts";
import { versesPassage, type Passage } from "./passage.ts";
import { place, spanCount, type Scheme, type Versification } from "./versification.ts";

/** Positions from `start` up to, not including, `end`. */
interface Run {
  start: number;
  end: number;
}

/** One chapter the set touches: how many of its verses the set holds. */
export interface ChapterCoverage {
  book: BookID;
  chapter: number;
  covered: number;
  verses: number;
}

export function isWholeChapter(coverage: ChapterCoverage): boolean {
  return coverage.covered === coverage.verses;
}

export class VerseSet {
  readonly scheme: Scheme;
  #runs = new Map<BookID, Run[]>();

  constructor(scheme: Scheme = "english") {
    this.scheme = scheme;
  }

  static of(passages: Iterable<Passage>, versification: Versification): VerseSet {
    const set = new VerseSet(versification.scheme);
    for (const passage of passages) set.insert(passage, versification);
    return set;
  }

  insert(passage: Passage, versification: Versification): void {
    if (passage.scheme !== this.scheme || versification.scheme !== this.scheme) {
      throw new Error("one scheme per set");
    }
    // A passage is checked against its scheme when it is made, so both ends
    // have positions.
    const first = versification.position(passage.start, passage.book) ?? 0;
    const last = versification.position(passage.end, passage.book) ?? 0;
    this.#runs.set(
      passage.book,
      union(this.#runs.get(passage.book) ?? [], [{ start: first, end: last + 1 }]),
    );
  }

  get isEmpty(): boolean {
    return this.#runs.size === 0;
  }

  /** How many verses the set holds. */
  get count(): number {
    let total = 0;
    for (const runs of this.#runs.values()) total += size(runs);
    return total;
  }

  /** How many verses of the book the set holds. */
  countIn(book: BookID): number {
    return size(this.#runs.get(book) ?? []);
  }

  get books(): Set<BookID> {
    return new Set(this.#runs.keys());
  }

  union(other: VerseSet): VerseSet {
    return this.#combine(other, union);
  }

  intersection(other: VerseSet): VerseSet {
    return this.#combine(other, intersection);
  }

  subtracting(other: VerseSet): VerseSet {
    return this.#combine(other, difference);
  }

  /** The verses given more than once among the passages. */
  static repeats(passages: Iterable<Passage>, versification: Versification): VerseSet {
    let seen = new VerseSet(versification.scheme);
    let repeated = new VerseSet(versification.scheme);
    for (const passage of passages) {
      const verses = VerseSet.of([passage], versification);
      repeated = repeated.union(seen.intersection(verses));
      seen = seen.union(verses);
    }
    return repeated;
  }

  /** The set as the fewest passages, in the scheme's book order. */
  passages(versification: Versification): Passage[] {
    this.#sameScheme(versification);
    return versification.books.flatMap((book) =>
      (this.#runs.get(book) ?? []).map((run) => {
        const start = versification.placeAt(run.start, book);
        const end = versification.placeAt(run.end - 1, book);
        if (!start || !end) throw new Error("a run outside its book");
        return versesPassage(book, start, end, versification);
      }),
    );
  }

  /**
   * Every chapter the set touches, whole or in part, in the scheme's book
   * order. A chapter with even one verse in the set is listed.
   */
  chapters(versification: Versification): ChapterCoverage[] {
    this.#sameScheme(versification);
    const result: ChapterCoverage[] = [];
    for (const book of versification.books) {
      const runs = this.#runs.get(book);
      const chapters = versification.chapters(book);
      if (!runs || !chapters) continue;
      for (let chapter = chapters.first; chapter <= chapters.last; chapter += 1) {
        const verses = versification.verses(book, chapter);
        if (!verses) continue;
        const first = versification.position(place(chapter, verses.first), book) ?? 0;
        const covered = size(
          intersection(runs, [{ start: first, end: first + spanCount(verses) }]),
        );
        if (covered > 0) result.push({ book, chapter, covered, verses: spanCount(verses) });
      }
    }
    return result;
  }

  #sameScheme(versification: Versification): void {
    if (versification.scheme !== this.scheme) throw new Error("one scheme per set");
  }

  #combine(other: VerseSet, operation: (a: Run[], b: Run[]) => Run[]): VerseSet {
    if (other.scheme !== this.scheme) throw new Error("one scheme per set");
    const result = new VerseSet(this.scheme);
    for (const book of new Set([...this.#runs.keys(), ...other.#runs.keys()])) {
      const runs = operation(this.#runs.get(book) ?? [], other.#runs.get(book) ?? []);
      if (runs.length > 0) result.#runs.set(book, runs);
    }
    return result;
  }
}

function size(runs: Run[]): number {
  return runs.reduce((sum, run) => sum + run.end - run.start, 0);
}

/** Sorted, separate runs covering every position in either list. */
function union(a: Run[], b: Run[]): Run[] {
  const result: Run[] = [];
  for (const run of [...a, ...b].sort((x, y) => x.start - y.start)) {
    const last = result.at(-1);
    if (last && run.start <= last.end) last.end = Math.max(last.end, run.end);
    else result.push({ ...run });
  }
  return result;
}

/** The positions in both lists. */
function intersection(a: Run[], b: Run[]): Run[] {
  const result: Run[] = [];
  let i = 0;
  let j = 0;
  while (i < a.length && j < b.length) {
    const x = a[i] as Run;
    const y = b[j] as Run;
    const start = Math.max(x.start, y.start);
    const end = Math.min(x.end, y.end);
    if (start < end) result.push({ start, end });
    if (x.end < y.end) i += 1;
    else j += 1;
  }
  return result;
}

/** The positions in the first list and not the second. */
function difference(a: Run[], b: Run[]): Run[] {
  const result: Run[] = [];
  let j = 0;
  for (const run of a) {
    let start = run.start;
    while (j < b.length && (b[j] as Run).end <= start) j += 1;
    let k = j;
    while (k < b.length && (b[k] as Run).start < run.end) {
      const cut = b[k] as Run;
      if (cut.start > start) result.push({ start, end: cut.start });
      start = Math.max(start, cut.end);
      k += 1;
    }
    if (start < run.end) result.push({ start, end: run.end });
  }
  return result;
}
