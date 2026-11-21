// The welcome after a gap (docs/engine.md, "Returning after a break"), as
// Swift's Welcome gives it: the choices that apply, each with what it would
// set. "Welcome back. Here's where you left off." Never a count of days.
import {
  addDays,
  civilDateFromOrdinal,
  CivilDateError,
  compareCivilDates,
  ordinal,
  type CivilDate,
} from "./civil-date.ts";
import type { Enrollment, ReturnChoice } from "./journal.ts";
import type { EventBody } from "./preview.ts";
import { basisOf, readingDayFrom, readingDaysBetween } from "./today.ts";

export interface WelcomeOffer {
  readonly choice: ReturnChoice;
  /** The basis `spread` and `moveFinish` would set, from today. */
  readonly finish?: CivilDate;
  readonly remaining?: number;
  /** The most readings on one day under that basis. */
  readonly most?: number;
}

export interface Welcome {
  /** In the order the reader is offered them. */
  readonly offers: readonly WelcomeOffer[];
  /** The limit spreading would need, when it is not offered only because it is beyond the reader's limit. */
  readonly spreadNeeds?: number;
}

function dateOrNone(make: () => CivilDate): CivilDate | undefined {
  try {
    return make();
  } catch (error) {
    if (error instanceof CivilDateError) return undefined;
    throw error;
  }
}

/**
 * Whether there is a gap before `date`: two or more reading days strictly
 * between the anchor and that date. The anchor is the latest of the day
 * before the start, the last day the reader read, the last answer to a
 * welcome, and the day before the last resuming.
 */
export function hasGapBefore(enrollment: Enrollment, date: CivilDate): boolean {
  let anchor = ordinal(enrollment.start) - 1;
  for (const mark of enrollment.marks) {
    if (mark.kind !== "skipped" && compareCivilDates(mark.date, date) <= 0) {
      anchor = Math.max(anchor, ordinal(mark.date));
    }
  }
  let returned: number | undefined;
  let resumed: number | undefined;
  for (const event of enrollment.arranging) {
    if (event.kind === "returned") returned = ordinal(event.date);
    else if (event.kind === "resumed") resumed = ordinal(event.from) - 1;
  }
  anchor = Math.max(anchor, returned ?? anchor, resumed ?? anchor);
  const first = dateOrNone(() => civilDateFromOrdinal(anchor + 1));
  const last = dateOrNone(() => addDays(date, -1));
  return !!first && !!last && readingDaysBetween(enrollment, first, last) >= 2;
}

/**
 * The welcome to offer on `date`, or undefined when there is none: no gap, a
 * paused day, before the start, or a plan that is finished or ended.
 */
export function welcome(enrollment: Enrollment, date: CivilDate): Welcome | undefined {
  if (
    enrollment.ended ||
    compareCivilDates(date, enrollment.start) < 0 ||
    enrollment.isPaused(date) ||
    !hasGapBefore(enrollment, date)
  ) {
    return undefined;
  }
  if (enrollment.plan.schedule === "day-of-month") return { offers: [{ choice: "rejoin" }] };
  const unread = enrollment.plan.assignments.filter(
    (assignment) => enrollment.state({ assignment: assignment.id }) === "unread",
  ).length;
  if (unread === 0) return undefined;
  const offers: WelcomeOffer[] = [{ choice: "continue" }];
  let spreadNeeds: number | undefined;
  const arrangement = enrollment.arrangement(date);
  const basis = arrangement.behavior === "finish-date" ? basisOf(enrollment) : undefined;
  if (basis) {
    // Spread: the unread readings over the reading days left.
    const left = readingDaysBetween(enrollment, date, basis.finish);
    if (left > 0) {
      const most = Math.ceil(unread / left);
      if (most <= (arrangement.limit ?? most)) {
        offers.push({ choice: "spread", finish: basis.finish, remaining: unread, most });
      } else {
        spreadNeeds = most;
      }
    }
    // Move the finish: the present daily amount, from today.
    const scheduled = readingDaysBetween(enrollment, basis.first, basis.finish);
    let amount = scheduled > 0 ? Math.ceil(basis.remaining / scheduled) : basis.remaining;
    amount = Math.max(1, Math.min(amount, arrangement.limit ?? amount));
    const days = Math.ceil(unread / amount);
    const finish = readingDayFrom(enrollment, days, date);
    if (finish && compareCivilDates(finish, basis.finish) > 0) {
      offers.push({
        choice: "moveFinish",
        finish,
        remaining: unread,
        most: Math.ceil(unread / days),
      });
    }
  }
  return spreadNeeds === undefined ? { offers } : { offers, spreadNeeds };
}

/** The event that records the reader's answer to a welcome. */
export function welcomeAnswer(offer: WelcomeOffer, date: CivilDate): EventBody {
  return offer.finish && offer.remaining !== undefined
    ? {
        kind: "returned",
        date,
        choice: offer.choice,
        finish: offer.finish,
        remaining: offer.remaining,
      }
    : { kind: "returned", date, choice: offer.choice };
}
