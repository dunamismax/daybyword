// What the reader has done (docs/engine.md, "Progress"), as Swift's Progress
// gives it. Records describe activity: they do not measure faithfulness,
// maturity or understanding, and nothing built on them may suggest they do.
import {
  addDays,
  CivilDateError,
  civilDateText,
  compareCivilDates,
  type CivilDate,
} from "./civil-date.ts";
import type { BookID } from "./ids.ts";
import type { Enrollment, Journal, Slot } from "./journal.ts";
import type { Reading } from "./passage.ts";
import { assignmentPositions } from "./plan.ts";
import { parseReading, ReferenceFormatError } from "./reference-format.ts";
import { isReadingDay } from "./today.ts";
import { isWholeChapter, VerseSet, type ChapterCoverage } from "./verse-set.ts";
import type { Versification } from "./versification.ts";

/** An enrollment's readings by state. "62 of 89 readings read." */
export interface ProgressCounts {
  readonly read: number;
  readonly partlyRead: number;
  readonly skipped: number;
  readonly unread: number;
  readonly total: number;
}

/** One of the recent dates. */
export interface ProgressDay {
  readonly date: CivilDate;
  /** Whether the reader read on it, in any enrollment. */
  readonly isRead: boolean;
  /** Whether it was a reading day of any enrollment. */
  readonly isReadingDay: boolean;
}

/**
 * A book explored: its verses read of the verses it has, and its chapters
 * read whole and in part (P11.4). A partly read chapter is never counted as
 * read.
 */
export interface BookCoverage {
  readonly book: BookID;
  /** The verses read, each once. */
  readonly verses: number;
  /** The verses the book has. */
  readonly of: number;
  readonly wholeChapters: number;
  readonly partialChapters: number;
}

/** The verses the reader has read across every enrollment, each once. */
export interface ProgressCoverage {
  readonly verses: VerseSet;
  /**
   * Every chapter read from, in the scheme's book order. A chapter of a
   * reading marked part read with no verses stated is listed with none
   * covered unless other readings cover some of it.
   */
  readonly chapters: readonly ChapterCoverage[];
  /** The books explored, in the scheme's book order. */
  readonly books: readonly BookID[];
}

const before = (a: CivilDate, b: CivilDate) => compareCivilDates(a, b) < 0;

/** The date some days away, or undefined past either end of the calendar. */
function shifted(date: CivilDate, days: number): CivilDate | undefined {
  try {
    return addDays(date, days);
  } catch (error) {
    if (error instanceof CivilDateError) return undefined;
    throw error;
  }
}

/** Whether this is a sequence with no unread reading. */
export function isFinished(enrollment: Enrollment): boolean {
  return (
    enrollment.plan.schedule === "sequence" &&
    enrollment.settled.length >= assignmentPositions(enrollment.plan).size
  );
}

/**
 * The readings by state on `date`. A sequence's total is its readings. A
 * calendar enrollment's is the slots appointed from the start to that date
 * (or to the day it ended), paused days excluded, and with them any slot the
 * reader settled outside those days, so the states always add up to the
 * total.
 */
export function progressCounts(enrollment: Enrollment, date: CivilDate): ProgressCounts {
  const { plan, settled } = enrollment;
  const total =
    plan.schedule === "day-of-month"
      ? recordSlots(enrollment, date).length
      : assignmentPositions(plan).size;
  const count = (state: string) => settled.filter((mark) => mark.state === state).length;
  return {
    read: count("read"),
    partlyRead: count("partlyRead"),
    skipped: count("skipped"),
    unread: total - settled.length,
    total,
  };
}

/**
 * The slots the record holds on `date` (P11.5): a sequence's every assignment
 * in reading order; a calendar enrollment's slots appointed from the start to
 * that date (or to the day it ended), paused days excluded, with any slot the
 * reader settled outside those days, in date order. The readings by state
 * count these.
 */
export function recordSlots(enrollment: Enrollment, date: CivilDate): Slot[] {
  const { plan, settled, start, ended } = enrollment;
  if (plan.schedule !== "day-of-month") {
    return plan.assignments.map((assignment) => ({ assignment: assignment.id }));
  }
  const positions = assignmentPositions(plan);
  const last = ended && before(ended, date) ? ended : date;
  const slots: Slot[] = [];
  for (let day: CivilDate | undefined = start; day && !before(last, day); day = shifted(day, 1)) {
    if (!enrollment.isPaused(day) && positions.has(day.day)) {
      slots.push({ assignment: day.day, appointed: day });
    }
  }
  for (const mark of settled) {
    const { appointed } = mark;
    if (
      appointed &&
      (before(appointed, start) || before(last, appointed) || enrollment.isPaused(appointed))
    ) {
      slots.push({ assignment: mark.assignment, appointed });
    }
  }
  return slots.sort((a, b) =>
    a.appointed && b.appointed ? compareCivilDates(a.appointed, b.appointed) : 0,
  );
}

/**
 * Whether `date` is a reading day on which the enrollment still had something
 * to ask: a finished sequence asks nothing after the last day the reader
 * marked in it, so its later days neither count as reading days among the
 * recent ones nor weigh on the streak.
 */
export function expectsReading(enrollment: Enrollment, date: CivilDate): boolean {
  if (!isReadingDay(enrollment, date)) return false;
  if (!isFinished(enrollment) || enrollment.settled.length === 0) return true;
  return enrollment.settled.some((mark) => !before(mark.date, date));
}

/**
 * The dates on which the reader read, as text: the date of every active
 * `completed` or `partlyCompleted` event, in any enrollment. A reading begun
 * one day and finished the next is two days read, though its slot keeps only
 * the later mark.
 */
export function readDates(journal: Journal): Set<string> {
  const dates = new Set<string>();
  for (const enrollment of journal.enrollments) {
    for (const mark of enrollment.marks) {
      if (mark.kind !== "skipped") dates.add(civilDateText(mark.date));
    }
  }
  return dates;
}

/**
 * The `count` dates ending on `date`, earliest first, each with whether the
 * reader read on it and whether it was a reading day of any enrollment.
 * Dates before the calendar begins are left out.
 */
export function recentDays(journal: Journal, date: CivilDate, count = 7): ProgressDay[] {
  const read = readDates(journal);
  const days: ProgressDay[] = [];
  for (let back = count - 1; back >= 0; back -= 1) {
    const day = shifted(date, -back);
    if (!day) continue;
    days.push({
      date: day,
      isRead: read.has(civilDateText(day)),
      isReadingDay: journal.enrollments.some((enrollment) => expectsReading(enrollment, day)),
    });
  }
  return days;
}

/**
 * The streak on `date` (D17): the consecutive reading days, of any enrollment
 * that is not ended, on which the reader read, counting back from that date,
 * or from the last reading day before it when it is not yet read. Rest days
 * and paused days neither break it nor add to it.
 */
export function streak(journal: Journal, date: CivilDate): number {
  const open = journal.enrollments.filter((enrollment) => !enrollment.ended);
  if (open.length === 0) return 0;
  const earliest = open
    .map((enrollment) => enrollment.start)
    .reduce((a, b) => (before(b, a) ? b : a));
  const read = readDates(journal);
  let count = 0;
  for (
    let day: CivilDate | undefined = date;
    day && !before(day, earliest);
    day = shifted(day, -1)
  ) {
    const at = day;
    if (!open.some((enrollment) => expectsReading(enrollment, at))) continue;
    if (read.has(civilDateText(at))) count += 1;
    else if (compareCivilDates(at, date) !== 0) break;
  }
  return count;
}

/**
 * Coverage across all enrollments, each verse once: every reading marked
 * read, and the stated verses of readings marked part read, as far as they
 * are verses of that reading. A reading marked part read with no such verses
 * adds none: its chapters are listed and its books count as explored.
 */
export function coverage(journal: Journal, versification: Versification): ProgressCoverage {
  let verses = new VerseSet(versification.scheme);
  let touched = new VerseSet(versification.scheme);
  for (const enrollment of journal.enrollments) {
    const covered = enrollmentCoverage(enrollment, versification);
    verses = verses.union(covered.verses);
    touched = touched.union(covered.touched);
  }

  const all = verses.union(touched);
  const covered = new Map(
    verses
      .chapters(versification)
      .map((chapter) => [`${chapter.book} ${chapter.chapter}`, chapter.covered]),
  );
  const books = all.books;
  return {
    verses,
    chapters: all.chapters(versification).map((chapter) => ({
      ...chapter,
      covered: covered.get(`${chapter.book} ${chapter.chapter}`) ?? 0,
    })),
    books: versification.books.filter((book) => books.has(book)),
  };
}

/**
 * One enrollment's part of coverage: the verses its readings marked read
 * cover, with the stated verses of those marked part read, as far as they
 * are verses of that reading; and, apart, the readings marked part read with
 * no such verses, whose chapters are listed and whose books are explored
 * though they add no verses.
 */
export function enrollmentCoverage(
  enrollment: Enrollment,
  versification: Versification,
): { readonly verses: VerseSet; readonly touched: VerseSet } {
  let verses = new VerseSet(versification.scheme);
  let touched = new VerseSet(versification.scheme);
  const readings = new Map<number, Reading>();
  for (const assignment of enrollment.plan.assignments) {
    if (!readings.has(assignment.id)) readings.set(assignment.id, assignment.reading);
  }
  for (const mark of enrollment.settled) {
    const reading = readings.get(mark.assignment);
    if (mark.state === "skipped" || reading?.passages[0]?.scheme !== versification.scheme) continue;
    const whole = VerseSet.of(reading.passages, versification);
    if (mark.state === "read") {
      verses = verses.union(whole);
      continue;
    }
    let stated = new VerseSet(versification.scheme);
    if (mark.verses !== undefined) {
      try {
        const said = parseReading(mark.verses, versification);
        stated = VerseSet.of(said.passages, versification).intersection(whole);
      } catch (error) {
        if (!(error instanceof ReferenceFormatError)) throw error;
      }
    }
    if (stated.isEmpty) touched = touched.union(whole);
    else verses = verses.union(stated);
  }
  return { verses, touched };
}

/**
 * Each book explored, in the scheme's book order, with its verses read of the
 * verses it has and its chapters read whole and in part (P11.4). Repeats add
 * nothing: each verse counts once.
 */
export function coverageByBook(
  covered: ProgressCoverage,
  versification: Versification,
): BookCoverage[] {
  return covered.books.map((book) => {
    const touched = covered.chapters.filter((chapter) => chapter.book === book);
    const whole = touched.filter(isWholeChapter).length;
    return {
      book,
      verses: covered.verses.countIn(book),
      of: versification.verseCount(book),
      wholeChapters: whole,
      partialChapters: touched.length - whole,
    };
  });
}
