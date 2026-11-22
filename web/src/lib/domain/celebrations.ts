// What the reader did that Day by Word quietly notices on the day it happened
// (docs/engine.md, "Quiet celebrations"), as Swift's Celebration gives it:
// words, never confetti, never a comparison with anyone, and never a count
// of days. Like every record they describe activity.
import {
  addDays,
  civilDateFromOrdinal,
  CivilDateError,
  civilDateText,
  compareCivilDates,
  ordinal,
  weekday,
  type CivilDate,
} from "./civil-date.ts";
import type { EventID } from "./event-id.ts";
import type { BookID } from "./ids.ts";
import { Enrollment, type Journal } from "./journal.ts";
import { enrollmentCoverage, expectsReading, isFinished, readDates } from "./progress.ts";
import { readingDaysBetween } from "./today.ts";
import type { Versification } from "./versification.ts";

export type Celebration =
  /** Reading again after a gap. "You've picked up where you left off." */
  | { readonly kind: "returned"; readonly enrollment: EventID }
  /** Every verse of a book now read in this enrollment. "You've read all of Ruth." */
  | { readonly kind: "finishedBook"; readonly enrollment: EventID; readonly book: BookID }
  /** A sequence with no unread reading left. "You've finished Gospels at your pace." */
  | { readonly kind: "finishedPlan"; readonly enrollment: EventID }
  /** Every reading day of the week read, on the last of them. */
  | { readonly kind: "keptRhythm" };

function dateOrNone(make: () => CivilDate): CivilDate | undefined {
  try {
    return make();
  } catch (error) {
    if (error instanceof CivilDateError) return undefined;
    throw error;
  }
}

/**
 * The enrollment as its active marks dated on the days `keep` accepts would
 * make it alone: "the record before" a date, or "through" it.
 */
function record(enrollment: Enrollment, keep: (date: CivilDate) => boolean): Enrollment {
  return new Enrollment(
    enrollment.enrolled,
    enrollment.plan,
    enrollment.marks.filter((mark) => keep(mark.date)),
    enrollment.arranging,
  );
}

/**
 * Whether the reader returned on `date` after a gap: they read in the
 * enrollment on it and on an earlier date, it is on or after the start and
 * not paused, the plan was not finished in the record before it, and two or
 * more reading days lie strictly between the anchor and it. The anchor is the
 * latest of the day before the start, the last earlier date read, and the day
 * before the last resuming on or before `date`; answering the welcome is not
 * reading, so it does not move it.
 */
function hasReturned(enrollment: Enrollment, date: CivilDate, before: Enrollment): boolean {
  const reading = enrollment.marks.filter((mark) => mark.kind !== "skipped");
  if (
    !reading.some((mark) => compareCivilDates(mark.date, date) === 0) ||
    compareCivilDates(date, enrollment.start) < 0 ||
    enrollment.isPaused(date) ||
    isFinished(before)
  ) {
    return false;
  }
  const earlier = reading
    .filter((mark) => compareCivilDates(mark.date, date) < 0)
    .map((mark) => ordinal(mark.date));
  if (earlier.length === 0) return false;
  const last = Math.max(...earlier);
  let resumed: number | undefined;
  for (const event of enrollment.arranging) {
    if (event.kind === "resumed" && compareCivilDates(event.from, date) <= 0) {
      resumed = ordinal(event.from) - 1;
    }
  }
  const anchor = Math.max(ordinal(enrollment.start) - 1, last, resumed ?? last);
  const first = dateOrNone(() => civilDateFromOrdinal(anchor + 1));
  const end = dateOrNone(() => addDays(date, -1));
  return !!first && !!end && readingDaysBetween(enrollment, first, end) >= 2;
}

/**
 * Whether `date` is the last reading day of its week (Monday to Sunday), the
 * week has at least two, and the reader read on every one of them up to
 * `date`. Reading days are those of any enrollment that has not ended, as for
 * the streak; rest days and paused days are not asked about.
 */
function keptRhythm(journal: Journal, date: CivilDate): boolean {
  const open = journal.enrollments.filter((enrollment) => !enrollment.ended);
  const isReadingDay = (day: CivilDate) =>
    open.some((enrollment) => expectsReading(enrollment, day));
  const monday = dateOrNone(() => addDays(date, 1 - weekday(date)));
  if (!isReadingDay(date) || !monday) return false;
  const read = readDates(journal);
  let count = 0;
  for (let offset = 0; offset < 7; offset += 1) {
    const day = dateOrNone(() => addDays(monday, offset));
    if (!day) break;
    if (!isReadingDay(day)) continue;
    if (compareCivilDates(day, date) > 0 || !read.has(civilDateText(day))) return false;
    count += 1;
  }
  return count >= 2;
}

/**
 * The celebrations on `date`: for each enrollment that has not ended, in the
 * order the reader started them, its return, the books it finished (in the
 * scheme's order) and its finishing; then the week's rhythm.
 */
export function celebrations(
  journal: Journal,
  date: CivilDate,
  versification: Versification,
): Celebration[] {
  const found: Celebration[] = [];
  for (const enrollment of journal.enrollments) {
    if (enrollment.ended) continue;
    const before = record(enrollment, (day) => compareCivilDates(day, date) < 0);
    const through = record(enrollment, (day) => compareCivilDates(day, date) <= 0);
    const id = enrollment.id;
    if (hasReturned(enrollment, date, before)) found.push({ kind: "returned", enrollment: id });
    const had = enrollmentCoverage(before, versification).verses;
    const has = enrollmentCoverage(through, versification).verses;
    const books = has.books;
    for (const book of versification.books) {
      if (!books.has(book)) continue;
      const verses = versification.verseCount(book);
      if (has.countIn(book) === verses && had.countIn(book) < verses) {
        found.push({ kind: "finishedBook", enrollment: id, book });
      }
    }
    if (isFinished(through) && !isFinished(before)) {
      found.push({ kind: "finishedPlan", enrollment: id });
    }
  }
  if (keptRhythm(journal, date)) found.push({ kind: "keptRhythm" });
  return found;
}
