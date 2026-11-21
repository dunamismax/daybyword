// What one enrollment asks of the reader on one date (docs/engine.md,
// "Today" and the three behaviors), as Swift's Today gives it: a pure answer
// from the folded journal and the date the client resolved at the edge (E7).
import {
  addDays,
  CivilDateError,
  compareCivilDates,
  daysBetween,
  daysInMonth,
  weekday,
  type CivilDate,
} from "./civil-date.ts";
import type { Enrollment, Slot, SlotState } from "./journal.ts";
import { assignmentPositions } from "./plan.ts";

export type TodayStatus =
  "upcoming" | "reading" | "done" | "open" | "rest" | "paused" | "finished" | "ended";

/** Where a pace enrollment is heading. Projected, never promised. */
export interface Projection {
  /** At one reading each reading day from the first open day. */
  readonly plan?: CivilDate;
  /** At the pace of the 28 days before today, when there is enough to go on. */
  readonly recent?: CivilDate;
  /** Had one reading been read every reading day since the start. */
  readonly unbroken?: CivilDate;
}

/** A finish-date enrollment's schedule: its basis and where the reader stands against it. */
export interface Schedule {
  readonly first: CivilDate;
  readonly finish: CivilDate;
  /** The readings unread when the basis was set. */
  readonly remaining: number;
  /** The reading days from the first day to the finish. */
  readonly scheduledDays: number;
  /** The fewest and the most readings the basis puts on one day. */
  readonly least: number;
  readonly most: number;
  /** The words of the heaviest day still ahead; absent when a reading has no word count, or none is unread. */
  readonly heaviestWords?: number;
  /** The readings due before today and not yet settled. */
  readonly outstanding: number;
  /** The readings the basis gives today. */
  readonly share: number;
  /** The most readings on one reading day the reader accepts. */
  readonly limit?: number;
  /** The earliest finish that fits the limit, when `most` is beyond it. */
  readonly finishWithinLimit?: CivilDate;
}

/** A calendar enrollment's day. */
export interface CalendarDay {
  /** Today's appointment, whatever the status. */
  readonly appointment: Slot;
  readonly state: SlotState;
  /** On the last day of a short month, the readings it does not appoint. */
  readonly notAppointed: readonly number[];
  /** The unread slots from the start to yesterday, paused days excluded. */
  readonly missed: number;
}

export interface Today {
  readonly status: TodayStatus;
  /** Whether today is one of the reader's reading days. */
  readonly isReadingDay: boolean;
  /** The readings to read today, in reading order. */
  readonly readings: readonly Slot[];
  /** The slots read or partly read with today's date, in reading order. */
  readonly readToday: readonly Slot[];
  /** The next unread reading of a sequence. */
  readonly next?: Slot;
  readonly projection?: Projection;
  readonly schedule?: Schedule;
  readonly calendar?: CalendarDay;
}

/** Leaves out undefined fields, so optional fields are absent, never undefined. */
function present<T extends object>(value: T): { [K in keyof T]: Exclude<T[K], undefined> } {
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as {
    [K in keyof T]: Exclude<T[K], undefined>;
  };
}

const before = (a: CivilDate, b: CivilDate) => compareCivilDates(a, b) < 0;
const later = (a: CivilDate, b: CivilDate) => (before(a, b) ? b : a);
const earlier = (a: CivilDate, b: CivilDate) => (before(a, b) ? a : b);

/** The date some days away, or undefined past either end of the calendar. */
function shifted(date: CivilDate, days: number): CivilDate | undefined {
  try {
    return addDays(date, days);
  } catch (error) {
    if (error instanceof CivilDateError) return undefined;
    throw error;
  }
}

/**
 * Whether a date is a reading day (docs/engine.md, "Reading days and rest
 * days"): on or after the start, a weekday arranged for that date, not
 * paused, and not after the enrollment ended.
 */
export function isReadingDay(enrollment: Enrollment, date: CivilDate): boolean {
  if (before(date, enrollment.start) || enrollment.isPaused(date)) return false;
  if (enrollment.ended && before(enrollment.ended, date)) return false;
  return enrollment.arrangement(date).readingDays.includes(weekday(date));
}

/** Walks the days from `first` that are not paused and not after the end, until `visit` says stop. */
function walk(enrollment: Enrollment, first: CivilDate, visit: (day: CivilDate) => boolean): void {
  let day: CivilDate | undefined = later(first, enrollment.start);
  while (day) {
    const at: CivilDate = day;
    if (enrollment.ended && before(enrollment.ended, at)) return;
    const pause = enrollment.pauses.find(
      (range) => !before(at, range.from) && (!range.until || before(at, range.until)),
    );
    if (pause) {
      day = pause.until;
      continue;
    }
    if (enrollment.arrangement(at).readingDays.includes(weekday(at)) && !visit(at)) return;
    day = shifted(at, 1);
  }
}

/**
 * The `count`-th reading day counting from `date`, which counts when it is
 * one; undefined when it never comes (the enrollment ended, a pause with no
 * end, or past the last date).
 */
export function readingDayFrom(
  enrollment: Enrollment,
  count: number,
  date: CivilDate,
): CivilDate | undefined {
  if (count < 1) return undefined;
  let left = count;
  let found: CivilDate | undefined;
  walk(enrollment, date, (day) => {
    left -= 1;
    if (left === 0) found = day;
    return left > 0;
  });
  return found;
}

/** The reading days from one date to another, both included. */
export function readingDaysBetween(
  enrollment: Enrollment,
  first: CivilDate,
  last: CivilDate,
): number {
  let count = 0;
  walk(enrollment, first, (day) => {
    if (before(last, day)) return false;
    count += 1;
    return true;
  });
  return count;
}

export interface Basis {
  readonly first: CivilDate;
  readonly finish: CivilDate;
  readonly remaining: number;
}

/**
 * A finish-date schedule's basis: its first day, finish, and the readings
 * unread when it was set. The last active event that sets one is the basis.
 */
export function basisOf(enrollment: Enrollment): Basis | undefined {
  const total = enrollment.plan.assignments.length;
  let basis: Basis | undefined = enrollment.enrolled.finish && {
    first: enrollment.start,
    finish: enrollment.enrolled.finish,
    remaining: total,
  };
  for (const event of enrollment.arranging) {
    if (event.kind === "paused" || event.kind === "ended") continue;
    if (!event.finish || event.remaining === undefined) continue;
    basis = {
      first: event.kind === "returned" ? event.date : event.from,
      finish: event.finish,
      remaining: event.remaining,
    };
  }
  return basis && { ...basis, remaining: Math.min(basis.remaining, total) };
}

/** The settled readings due once `date` is over. */
export function targetAfter(enrollment: Enrollment, basis: Basis, date: CivilDate): number {
  const total = enrollment.plan.assignments.length;
  if (before(date, basis.first)) return total - basis.remaining;
  const scheduled = readingDaysBetween(enrollment, basis.first, basis.finish);
  if (scheduled === 0 || before(basis.finish, date)) return total;
  return (
    total -
    basis.remaining +
    Math.floor((readingDaysBetween(enrollment, basis.first, date) * basis.remaining) / scheduled)
  );
}

function scheduleOn(
  enrollment: Enrollment,
  basis: Basis,
  date: CivilDate,
  unread: readonly Slot[],
): Schedule {
  const total = enrollment.plan.assignments.length;
  const scheduled = readingDaysBetween(enrollment, basis.first, basis.finish);
  const yesterday = shifted(date, -1);
  const dueBefore = yesterday ? targetAfter(enrollment, basis, yesterday) : total - basis.remaining;
  const isScheduled =
    isReadingDay(enrollment, date) && !before(date, basis.first) && !before(basis.finish, date);
  const least = scheduled > 0 ? Math.floor(basis.remaining / scheduled) : basis.remaining;
  const most = scheduled > 0 ? Math.ceil(basis.remaining / scheduled) : basis.remaining;

  // Each unread reading's scheduled day: the k-th of the basis's readings is
  // expected on scheduled day ⌈k × N ÷ R⌉.
  let heaviestWords: number | undefined;
  if (scheduled > 0 && unread.length > 0) {
    const words = new Map<number, number>();
    const counts = enrollment.plan.words;
    const counted = unread.every((slot, index) => {
      const count = counts?.get(slot.assignment);
      if (count === undefined) return false;
      const place = Math.min(
        Math.max(basis.remaining - unread.length + index + 1, 1),
        basis.remaining,
      );
      const day = Math.ceil((place * scheduled) / basis.remaining);
      words.set(day, (words.get(day) ?? 0) + count);
      return true;
    });
    if (counted) heaviestWords = Math.max(...words.values());
  }

  const limit = enrollment.arrangement(date).limit;
  return present({
    first: basis.first,
    finish: basis.finish,
    remaining: basis.remaining,
    scheduledDays: scheduled,
    least,
    most,
    heaviestWords,
    outstanding: Math.max(0, dueBefore - (total - unread.length)),
    share: isScheduled ? targetAfter(enrollment, basis, date) - dueBefore : 0,
    limit,
    finishWithinLimit:
      limit !== undefined && most > limit
        ? readingDayFrom(enrollment, Math.ceil(basis.remaining / limit), basis.first)
        : undefined,
  });
}

function projectionOn(
  enrollment: Enrollment,
  date: CivilDate,
  unread: number,
  fromToday: boolean,
): Projection {
  const firstOpen = fromToday ? date : shifted(date, 1);
  const yesterday = shifted(date, -1);
  let recent: CivilDate | undefined;
  // The 28 days before today, and not before the start.
  if (yesterday && firstOpen) {
    const window = later(enrollment.start, shifted(date, -28) ?? enrollment.start);
    if (!before(yesterday, window)) {
      const read = enrollment.settled.filter(
        (mark) =>
          mark.state !== "skipped" && !before(mark.date, window) && !before(yesterday, mark.date),
      ).length;
      const days = readingDaysBetween(enrollment, window, yesterday);
      if (days >= 5 && read >= 1) {
        recent = readingDayFrom(enrollment, Math.ceil((unread * days) / read), firstOpen);
      }
    }
  }
  return present({
    plan: firstOpen && readingDayFrom(enrollment, unread, firstOpen),
    recent,
    unbroken: readingDayFrom(enrollment, enrollment.plan.assignments.length, enrollment.start),
  });
}

function calendarDay(
  enrollment: Enrollment,
  date: CivilDate,
  readingDay: boolean,
  readToday: readonly Slot[],
): Today {
  const slot: Slot = { assignment: date.day, appointed: date };
  const state = enrollment.state(slot);
  const positions = assignmentPositions(enrollment.plan);
  const isAppointed = !before(date, enrollment.start) && positions.has(date.day);
  const status: TodayStatus = enrollment.ended
    ? "ended"
    : before(date, enrollment.start)
      ? "upcoming"
      : enrollment.isPaused(date)
        ? "paused"
        : !readingDay
          ? "rest"
          : !isAppointed || state === "skipped"
            ? "open"
            : state === "unread"
              ? "reading"
              : "done";

  let calendar: CalendarDay | undefined;
  if (isAppointed && status !== "ended") {
    // The days from the start to yesterday, less the paused ones and the
    // slots settled on the others.
    let missed = daysBetween(enrollment.start, date);
    for (const pause of enrollment.pauses) {
      const from = later(pause.from, enrollment.start);
      const until = earlier(pause.until ?? date, date);
      if (before(from, until)) missed -= daysBetween(from, until);
    }
    missed -= enrollment.settled.filter(
      (mark) =>
        mark.appointed &&
        !before(mark.appointed, enrollment.start) &&
        before(mark.appointed, date) &&
        !enrollment.isPaused(mark.appointed),
    ).length;
    const last = daysInMonth(date.month, date.year);
    const notAppointed: number[] = [];
    if (date.day === last) {
      for (let day = last + 1; day <= 31; day += 1) if (positions.has(day)) notAppointed.push(day);
    }
    calendar = { appointment: slot, state, notAppointed, missed };
  }
  return present({
    status,
    isReadingDay: readingDay,
    readings: status === "reading" ? [slot] : [],
    readToday,
    calendar,
  });
}

/** What an enrollment asks of the reader on `date`. */
export function today(enrollment: Enrollment, date: CivilDate): Today {
  const readingDay = isReadingDay(enrollment, date);
  const readToday: Slot[] = enrollment.settled
    .filter((mark) => mark.state !== "skipped" && compareCivilDates(mark.date, date) === 0)
    .map((mark) =>
      mark.appointed
        ? { assignment: mark.assignment, appointed: mark.appointed }
        : { assignment: mark.assignment },
    );
  if (enrollment.plan.schedule === "day-of-month") {
    return calendarDay(enrollment, date, readingDay, readToday);
  }

  const total = enrollment.plan.assignments.length;
  const unread: Slot[] = enrollment.plan.assignments
    .map((assignment) => ({ assignment: assignment.id }))
    .filter((slot) => enrollment.state(slot) === "unread");
  const basis =
    enrollment.arrangement(date).behavior === "finish-date" ? basisOf(enrollment) : undefined;
  const schedule = basis && scheduleOn(enrollment, basis, date, unread);
  // How many readings are today's, when today is a reading day.
  let count = unread.length === 0 ? 0 : 1;
  if (basis && schedule) {
    const needed = Math.max(0, targetAfter(enrollment, basis, date) - (total - unread.length));
    const quota = schedule.share > 0 ? schedule.share : schedule.outstanding > 0 ? 1 : 0;
    count = Math.min(needed, Math.max(0, quota - readToday.length), unread.length);
  } else if (readToday.length > 0) {
    count = 0;
  }

  const status: TodayStatus = enrollment.ended
    ? "ended"
    : unread.length === 0
      ? "finished"
      : before(date, enrollment.start)
        ? "upcoming"
        : enrollment.isPaused(date)
          ? "paused"
          : !readingDay
            ? "rest"
            : count > 0
              ? "reading"
              : readToday.length === 0
                ? "open"
                : "done";

  const isOver = status === "ended" || status === "finished";
  return present({
    status,
    isReadingDay: readingDay,
    readings: status === "reading" ? unread.slice(0, count) : [],
    readToday,
    next: isOver || status === "upcoming" ? undefined : unread[0],
    projection:
      !schedule && !isOver && status !== "paused"
        ? projectionOn(enrollment, date, unread.length, status === "reading")
        : undefined,
    schedule: isOver ? undefined : schedule,
  });
}
