// ScheduledReminder rules (docs/engine.md, "Reminders"), as Swift's Reminders gives
// them. The engine works in local dates and wall-clock times and never in
// instants, so a 07:00 reminder stays at 07:00 when the clocks change or the
// reader travels.
import { addDays, CivilDateError, compareCivilDates, type CivilDate } from "./civil-date.ts";
import type { EventID } from "./event-id.ts";
import type { Journal, Slot } from "./journal.ts";
import { assignmentPositions } from "./plan.ts";
import { isReadingDay, today } from "./today.ts";
import type { WallTime } from "./wall-time.ts";

/** A local date and wall-clock time, with no zone: what a clock on the reader's wall shows. */
export interface LocalDateTime {
  readonly date: CivilDate;
  readonly time: WallTime;
}

/** A reminder to schedule, at a wall-clock time in whatever zone the device is then in. */
export interface ScheduledReminder {
  readonly enrollment: EventID;
  readonly at: LocalDateTime;
  /** The reading it is about: a calendar day's appointment, or a sequence's next reading as things stand now. */
  readonly slot?: Slot;
  /** Whether it is a reminder the reader snoozed. */
  readonly isSnooze: boolean;
}

/** From one wall-clock time up to another; they may cross midnight. */
export interface QuietHours {
  readonly from: WallTime;
  readonly until: WallTime;
}

/** A reminder the reader asked to see again, at a later time. */
export interface Snooze {
  readonly enrollment: EventID;
  readonly at: LocalDateTime;
}

/** The reader's settings for reminders, which belong to the device and not to any one enrollment. */
export interface ReminderSettings {
  readonly quietHours?: QuietHours;
  /** The most reminders on one date; absent for no limit. */
  readonly mostADay?: number;
  /** How many reminders to give. */
  readonly window: number;
  readonly snoozes?: readonly Snooze[];
}

/** How far ahead reminders are looked for: today and the 365 days after. */
export const reminderHorizon = 366;

const minutes = (time: WallTime) => time.hour * 60 + time.minute;

function compareLocal(a: LocalDateTime, b: LocalDateTime): number {
  return compareCivilDates(a.date, b.date) || minutes(a.time) - minutes(b.time);
}

/**
 * A time as quiet hours leave it: inside them it moves to their end when that
 * is later the same day, and is dropped (undefined) otherwise, so a reminder
 * never arrives the next morning about the day before.
 */
export function afterQuietHours(
  time: WallTime,
  quietHours: QuietHours | undefined,
): WallTime | undefined {
  if (!quietHours) return time;
  const [at, from, until] = [minutes(time), minutes(quietHours.from), minutes(quietHours.until)];
  if (from === until) return time;
  if (from < until) return from <= at && at < until ? quietHours.until : time;
  if (at < until) return quietHours.until;
  return at >= from ? undefined : time;
}

/**
 * The reminders to schedule from `now`, earliest first. The device schedules
 * them by wall-clock time and asks again whenever a reading is marked, a
 * setting changes, or the time zone changes.
 */
export function reminders(
  journal: Journal,
  now: LocalDateTime,
  settings: ReminderSettings,
): ScheduledReminder[] {
  if (settings.window <= 0) return [];
  const candidates: { order: number; reminder: ScheduledReminder }[] = [];

  journal.enrollments.forEach((enrollment, order) => {
    const answer = today(enrollment, now.date);
    if (answer.status === "ended" || answer.status === "finished") return;
    const isSequence = enrollment.plan.schedule === "sequence";
    const positions = assignmentPositions(enrollment.plan);
    const unread: Slot[] = isSequence
      ? enrollment.plan.assignments
          .map((assignment) => ({ assignment: assignment.id }))
          .filter((slot) => enrollment.state(slot) === "unread")
      : [];
    // A sequence gets no more reminders than it has unread readings.
    let left = isSequence ? Math.min(unread.length, settings.window) : settings.window;
    let day = now.date;
    for (let offset = 0; offset < reminderHorizon && left > 0; offset += 1) {
      if (offset > 0) {
        try {
          day = addDays(day, 1);
        } catch (error) {
          if (error instanceof CivilDateError) break;
          throw error;
        }
      }
      const arranged = isReadingDay(enrollment, day)
        ? enrollment.arrangement(day).reminder
        : undefined;
      if (!arranged) continue;
      if (offset === 0 && answer.status !== "reading") continue;
      const time = afterQuietHours(arranged, settings.quietHours);
      if (!time) continue;
      if (offset === 0 && minutes(time) <= minutes(now.time)) continue;
      let slot: Slot | undefined;
      if (isSequence) {
        // The next reading as things stand: if the reader reads nothing it
        // is still next, and a mark asks again.
        slot = unread[0];
      } else {
        const appointment: Slot = { assignment: day.day, appointed: day };
        if (!positions.has(day.day) || enrollment.state(appointment) !== "unread") continue;
        slot = appointment;
      }
      candidates.push({
        order,
        reminder: {
          enrollment: enrollment.id,
          at: { date: day, time },
          ...(slot ? { slot } : {}),
          isSnooze: false,
        },
      });
      left -= 1;
    }
  });

  // A snooze: one more, if it is still to come and the reading it was about
  // is still to read.
  for (const snooze of settings.snoozes ?? []) {
    const order = journal.enrollments.findIndex(
      (enrollment) => enrollment.id === snooze.enrollment,
    );
    const enrollment = journal.enrollments[order];
    if (!enrollment) continue;
    const answer = today(enrollment, now.date);
    const time = afterQuietHours(snooze.at.time, settings.quietHours);
    if (answer.status !== "reading" || !time) continue;
    const at = { date: snooze.at.date, time };
    if (compareLocal(at, now) <= 0) continue;
    const slot = answer.readings[0];
    candidates.push({
      order,
      reminder: { enrollment: snooze.enrollment, at, ...(slot ? { slot } : {}), isSnooze: true },
    });
  }

  candidates.sort(
    (a, b) =>
      compareLocal(a.reminder.at, b.reminder.at) ||
      a.order - b.order ||
      Number(a.reminder.isSnooze) - Number(b.reminder.isSnooze),
  );
  const kept: ScheduledReminder[] = [];
  let onDate = 0;
  for (const { reminder } of candidates) {
    // One reminder for an enrollment at one time.
    if (
      kept.some(
        (other) =>
          other.enrollment === reminder.enrollment && compareLocal(other.at, reminder.at) === 0,
      )
    ) {
      continue;
    }
    const last = kept.at(-1);
    if (!last || compareCivilDates(last.at.date, reminder.at.date) !== 0) onDate = 0;
    if (settings.mostADay !== undefined && onDate >= settings.mostADay) continue;
    kept.push(reminder);
    onDate += 1;
    if (kept.length === settings.window) break;
  }
  return kept;
}
