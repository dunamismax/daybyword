// Previews (docs/engine.md: "a preview is the fold itself"), as Swift's
// Preview has them. Before the reader confirms a return choice or a change,
// the interface shows the engine's answer for the journal with the
// candidate event added, beside its answer without. Nothing is written
// until the reader confirms.
import type { CivilDate } from "./civil-date.ts";
import { eventIDMilliseconds, makeEventID, type EventID } from "./event-id.ts";
import {
  Journal,
  type ChangedEvent,
  type Enrollment,
  type JournalEvent,
  type Reminder,
} from "./journal.ts";
import type { Behavior } from "./plan.ts";
import { basisOf } from "./today.ts";

type Record = "id" | "enrollment" | "at" | "zone" | "device";

/** What a candidate event says, apart from the record every event carries. */
export type EventBody = JournalEvent extends infer E
  ? E extends JournalEvent
    ? Omit<E, Record>
    : never
  : never;

/**
 * The journal with a candidate event added after every other. Nothing is
 * stored; the caller compares this journal's answers with the journal's
 * own. Undefined when no id can follow the last one.
 */
export function previewing(
  journal: Journal,
  body: EventBody,
  enrollment: EventID,
): Journal | undefined {
  const last = journal.events.at(-1);
  const id = makeEventID((last ? eventIDMilliseconds(last.id) : -1) + 1, Array<number>(10).fill(0));
  if (id === undefined) return undefined;
  const candidate = {
    ...body,
    id,
    enrollment,
    at: "1970-01-01T00:00:00Z",
    zone: "UTC",
    device: "preview",
  } as JournalEvent;
  return new Journal([...journal.events, candidate], journal.plans);
}

/** What the reader wants changed, from a date. */
export interface Change {
  readonly from: CivilDate;
  readonly start?: CivilDate;
  readonly readingDays?: readonly number[];
  readonly behavior?: Behavior;
  readonly finish?: CivilDate;
  readonly limit?: number;
  readonly reminder?: Reminder;
}

/**
 * A change to the arrangement (docs/engine.md, "Changing an enrollment"). On
 * a finish-date arrangement a change to the reading days, the finish date,
 * or to that behavior carries a new basis: the finish given, or else the
 * present one, over the readings unread now. A change to `finish-date` needs
 * a finish and a limit.
 */
export function changeOf(enrollment: Enrollment, change: Change): Omit<ChangedEvent, Record> {
  const { finish: wanted, ...rest } = change;
  const isScheduled =
    (change.behavior ?? enrollment.arrangement(change.from).behavior) === "finish-date";
  if (isScheduled && (change.readingDays || wanted || change.behavior)) {
    const unread = enrollment.plan.assignments.filter(
      (assignment) => enrollment.state({ assignment: assignment.id }) === "unread",
    ).length;
    const finish = wanted ?? basisOf(enrollment)?.finish;
    if (finish && unread > 0) return { kind: "changed", ...rest, finish, remaining: unread };
  }
  return { kind: "changed", ...rest };
}
