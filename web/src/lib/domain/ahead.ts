// The days ahead (docs/engine.md, "The days ahead"), as Swift's ComingDay
// gives them: what the sample week, the coming week and the printable
// checklist show.
import { addDays, CivilDateError, compareCivilDates, type CivilDate } from "./civil-date.ts";
import type { Enrollment, Slot } from "./journal.ts";
import { assignmentPositions } from "./plan.ts";
import { basisOf, isReadingDay, targetAfter, today } from "./today.ts";

export interface ComingDay {
  readonly date: CivilDate;
  /** Whether it is one of the reader's reading days. */
  readonly isReadingDay: boolean;
  /** The readings expected on it and not yet settled, in reading order. */
  readonly readings: readonly Slot[];
}

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
 * The `count` dates from `date`, each with the readings expected on it:
 * Today's own answer for each date in turn, supposing the reader reads what
 * each day shows and nothing more. A calendar enrollment's dates each have
 * their own appointment, on rest and paused days too. An ended enrollment has
 * none.
 */
export function comingDays(enrollment: Enrollment, date: CivilDate, count: number): ComingDay[] {
  const { plan } = enrollment;
  const days: ComingDay[] = [];
  const answer = today(enrollment, date);
  const positions = assignmentPositions(plan);
  const unread: Slot[] = plan.assignments
    .map((assignment) => ({ assignment: assignment.id }))
    .filter((slot) => enrollment.state(slot) === "unread");
  let settledCount = plan.assignments.length - unread.length;
  const basis = basisOf(enrollment);
  let day: CivilDate | undefined = date;
  for (let offset = 0; offset < count && day; offset += 1, day = shifted(day, 1)) {
    const at = day;
    const readingDay = isReadingDay(enrollment, at);
    if (plan.schedule === "day-of-month") {
      const slot: Slot = { assignment: at.day, appointed: at };
      const isAppointed =
        !enrollment.ended &&
        compareCivilDates(at, enrollment.start) >= 0 &&
        positions.has(at.day) &&
        enrollment.state(slot) === "unread";
      days.push({ date: at, isReadingDay: readingDay, readings: isAppointed ? [slot] : [] });
      continue;
    }

    let take = 0;
    if (offset === 0) {
      take = answer.readings.length;
    } else if (!enrollment.ended && readingDay && unread.length > 0) {
      take = 1;
      if (enrollment.arrangement(at).behavior === "finish-date" && basis) {
        const yesterday = shifted(at, -1);
        const before = yesterday ? targetAfter(enrollment, basis, yesterday) : 0;
        const after = targetAfter(enrollment, basis, at);
        const isScheduled =
          compareCivilDates(basis.first, at) <= 0 && compareCivilDates(at, basis.finish) <= 0;
        const share = isScheduled ? after - before : 0;
        const quota = share > 0 ? share : before > settledCount ? 1 : 0;
        take = Math.min(Math.max(0, after - settledCount), quota, unread.length);
      }
    }
    days.push({ date: at, isReadingDay: readingDay, readings: unread.splice(0, take) });
    settledCount += take;
  }
  return days;
}
