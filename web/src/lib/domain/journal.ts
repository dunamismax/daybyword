// The journal (docs/engine.md, "The journal"; docs/decisions.md E3, E40), as
// Swift's Journal folds it: a set of events, put in order of id and folded
// into each enrollment's state, the same in any arrival order. Nothing here
// reads a clock, a zone database or storage.
import {
  civilDateText,
  compareCivilDates,
  parseCivilDate,
  CivilDateError,
  type CivilDate,
} from "./civil-date.ts";
import { isEventID, type EventID } from "./event-id.ts";
import { isPlanID, type PlanID } from "./ids.ts";
import { assignmentPositions, behaviors, type Behavior, type PlanVersion } from "./plan.ts";
import { parseWallTime, wallTimeText, type WallTime } from "./wall-time.ts";

// MARK: Events

export type MarkKind = "completed" | "partlyCompleted" | "skipped";
export type ReturnChoice = "continue" | "spread" | "moveFinish" | "rejoin";
export const returnChoices: readonly ReturnChoice[] = [
  "continue",
  "spread",
  "moveFinish",
  "rejoin",
];
export const eventKinds = [
  "enrolled",
  "completed",
  "partlyCompleted",
  "skipped",
  "undone",
  "changed",
  "paused",
  "resumed",
  "returned",
  "ended",
] as const;
export type EventKind = (typeof eventKinds)[number];

/** A reminder time, or `off`. */
export type Reminder = WallTime | "off";

interface EventBase {
  readonly id: EventID;
  readonly enrollment: EventID;
  /** The instant it was made, `YYYY-MM-DDTHH:MM:SSZ`. A record; the engine never reads it. */
  readonly at: string;
  readonly zone: string;
  readonly device: string;
}

export interface EnrolledEvent extends EventBase {
  readonly kind: "enrolled";
  readonly plan: PlanID;
  readonly version: number;
  readonly behavior: Behavior;
  readonly start: CivilDate;
  readonly readingDays: readonly number[];
  readonly finish?: CivilDate;
  readonly limit?: number;
  readonly reminder?: Reminder;
}

export interface MarkingEvent extends EventBase {
  readonly kind: MarkKind;
  readonly assignment: number;
  /** The day the reading happened. */
  readonly date: CivilDate;
  /** The calendar slot's date, on a calendar plan. */
  readonly appointed?: CivilDate;
  /** Which part was read, on `partlyCompleted`, as the text it was given. */
  readonly verses?: string;
}

export interface UndoneEvent extends EventBase {
  readonly kind: "undone";
  readonly target: EventID;
}

export interface ChangedEvent extends EventBase {
  readonly kind: "changed";
  readonly from: CivilDate;
  readonly start?: CivilDate;
  readonly readingDays?: readonly number[];
  readonly behavior?: Behavior;
  readonly finish?: CivilDate;
  readonly limit?: number;
  readonly remaining?: number;
  readonly reminder?: Reminder;
}

export interface PausedEvent extends EventBase {
  readonly kind: "paused";
  readonly from: CivilDate;
}

export interface ResumedEvent extends EventBase {
  readonly kind: "resumed";
  readonly from: CivilDate;
  readonly finish?: CivilDate;
  readonly remaining?: number;
}

export interface ReturnedEvent extends EventBase {
  readonly kind: "returned";
  readonly date: CivilDate;
  readonly choice: ReturnChoice;
  readonly finish?: CivilDate;
  readonly remaining?: number;
}

export interface EndedEvent extends EventBase {
  readonly kind: "ended";
  readonly date: CivilDate;
}

export type JournalEvent =
  | EnrolledEvent
  | MarkingEvent
  | UndoneEvent
  | ChangedEvent
  | PausedEvent
  | ResumedEvent
  | ReturnedEvent
  | EndedEvent;

export type JournalErrorKind = "malformedEvent" | "conflictingEvent";

/** Why a journal is refused whole. Everything else is inert (`InertReason`). */
export class JournalError extends Error {
  override name = "JournalError";
  readonly kind: JournalErrorKind;
  constructor(kind: JournalErrorKind, message: string) {
    super(message);
    this.kind = kind;
  }
}

// MARK: Reading an event

/** Leaves out undefined fields, so optional fields are absent, never undefined. */
function present<T extends object>(value: T): { [K in keyof T]: Exclude<T[K], undefined> } {
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as {
    [K in keyof T]: Exclude<T[K], undefined>;
  };
}

type Read<T> = (value: unknown) => T | undefined;

const text = (value: unknown) => (typeof value === "string" ? value : undefined);

const readID: Read<EventID> = (value) => {
  const id = text(value);
  return id !== undefined && isEventID(id) ? id : undefined;
};

const readDate: Read<CivilDate> = (value) => {
  const written = text(value);
  if (written === undefined) return undefined;
  try {
    return parseCivilDate(written);
  } catch (error) {
    if (error instanceof CivilDateError) return undefined;
    throw error;
  }
};

const readPositive: Read<number> = (value) =>
  typeof value === "number" && Number.isSafeInteger(value) && value >= 1 ? value : undefined;

const readInstant: Read<string> = (value) => {
  const written = text(value);
  if (written === undefined) return undefined;
  const match = /^([0-9]{4}-[0-9]{2}-[0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z$/.exec(written);
  if (!match || readDate(match[1]) === undefined) return undefined;
  return Number(match[2]) <= 23 && Number(match[3]) <= 59 && Number(match[4]) <= 59
    ? written
    : undefined;
};

const readZone: Read<string> = (value) => {
  const zone = text(value);
  return zone !== undefined && /^[A-Za-z0-9_+\-/]{1,64}$/.test(zone) ? zone : undefined;
};

const readDevice: Read<string> = (value) => {
  const device = text(value);
  if (device === undefined) return undefined;
  // Counted in Unicode scalar values, as Swift counts them.
  const length = [...device].length;
  return length >= 1 && length <= 64 ? device : undefined;
};

const readPlanID: Read<PlanID> = (value) => {
  const id = text(value);
  return id !== undefined && isPlanID(id) ? id : undefined;
};

const oneOf =
  <T extends string>(values: readonly T[]): Read<T> =>
  (value) =>
    values.find((candidate) => candidate === value);

const readReadingDays: Read<readonly number[]> = (value) => {
  if (!Array.isArray(value) || value.length === 0) return undefined;
  let last = 0;
  for (const day of value as unknown[]) {
    if (typeof day !== "number" || !Number.isInteger(day) || day <= last || day > 7) {
      return undefined;
    }
    last = day;
  }
  return value as number[];
};

const readReminder: Read<Reminder> = (value) => {
  const written = text(value);
  if (written === undefined) return undefined;
  return written === "off" ? "off" : parseWallTime(written);
};

const readVerses: Read<string> = (value) => {
  const verses = text(value);
  return verses === undefined || verses === "" ? undefined : verses;
};

const what = {
  id: "a UUIDv7 id",
  kind: "a kind this version knows",
  instant: "an instant written YYYY-MM-DDTHH:MM:SSZ",
  zone: "a zone name",
  device: "a name of 1 to 64 characters",
  plan: "a plan id",
  positive: "a whole number from 1",
  behavior: "a behavior",
  date: "a date",
  readingDays: "a list of weekdays, ascending",
  reminder: "a time written HH:MM, or off",
  verses: "text",
  choice: "a return choice",
} as const;

/** One event's fields, read in the specification's order; the first fault is the error. */
class Fields {
  private readonly fields: Record<string, unknown>;
  private readonly number: number;

  constructor(value: unknown, number: number) {
    if (typeof value !== "object" || value === null || Array.isArray(value)) {
      throw new JournalError("malformedEvent", `event ${number} is not an object`);
    }
    this.fields = value as Record<string, unknown>;
    this.number = number;
  }

  has(name: string): boolean {
    return Object.hasOwn(this.fields, name);
  }

  required<T>(name: string, kind: keyof typeof what, read: Read<T>): T {
    if (!this.has(name)) {
      throw new JournalError("malformedEvent", `event ${this.number} has no "${name}"`);
    }
    const value = read(this.fields[name]);
    if (value === undefined) {
      throw new JournalError(
        "malformedEvent",
        `event ${this.number}'s "${name}" is not ${what[kind]}`,
      );
    }
    return value;
  }

  optional<T>(name: string, kind: keyof typeof what, read: Read<T>): T | undefined {
    return this.has(name) ? this.required(name, kind, read) : undefined;
  }

  /** Required when `needed`, and read when present either way. */
  when<T>(needed: boolean, name: string, kind: keyof typeof what, read: Read<T>): T | undefined {
    return needed ? this.required(name, kind, read) : this.optional(name, kind, read);
  }
}

/**
 * An event from its wire form (parsed JSON). `number` is its place among the
 * events as they were given, from 1, for the error's message.
 */
export function parseJournalEvent(value: unknown, number: number): JournalEvent {
  const fields = new Fields(value, number);
  const base: EventBase & { kind: EventKind } = {
    id: fields.required("id", "id", readID),
    kind: fields.required("kind", "kind", oneOf(eventKinds)),
    enrollment: fields.required("enrollment", "id", readID),
    at: fields.required("at", "instant", readInstant),
    zone: fields.required("zone", "zone", readZone),
    device: fields.required("device", "device", readDevice),
  };
  const { kind } = base;
  switch (kind) {
    case "enrolled": {
      const plan = fields.required("plan", "plan", readPlanID);
      const version = fields.required("version", "positive", readPositive);
      const behavior = fields.required("behavior", "behavior", oneOf(behaviors));
      const start = fields.required("start", "date", readDate);
      const readingDays = fields.required("readingDays", "readingDays", readReadingDays);
      const scheduled = behavior === "finish-date";
      return present({
        ...base,
        kind,
        plan,
        version,
        behavior,
        start,
        readingDays,
        finish: fields.when(scheduled, "finish", "date", readDate),
        limit: fields.when(scheduled, "limit", "positive", readPositive),
        reminder: fields.optional("reminder", "reminder", readReminder),
      });
    }
    case "completed":
    case "partlyCompleted":
    case "skipped":
      return present({
        ...base,
        kind,
        assignment: fields.required("assignment", "positive", readPositive),
        date: fields.required("date", "date", readDate),
        appointed: fields.optional("appointed", "date", readDate),
        verses:
          kind === "partlyCompleted" ? fields.optional("verses", "verses", readVerses) : undefined,
      });
    case "undone":
      return { ...base, kind, target: fields.required("target", "id", readID) };
    case "changed": {
      const from = fields.required("from", "date", readDate);
      const start = fields.optional("start", "date", readDate);
      const readingDays = fields.optional("readingDays", "readingDays", readReadingDays);
      const behavior = fields.optional("behavior", "behavior", oneOf(behaviors));
      const scheduled = behavior === "finish-date";
      return present({
        ...base,
        kind,
        from,
        start,
        readingDays,
        behavior,
        finish: fields.when(scheduled || fields.has("remaining"), "finish", "date", readDate),
        limit: fields.when(scheduled, "limit", "positive", readPositive),
        remaining: fields.when(
          scheduled || fields.has("finish"),
          "remaining",
          "positive",
          readPositive,
        ),
        reminder: fields.optional("reminder", "reminder", readReminder),
      });
    }
    case "paused":
      return { ...base, kind, from: fields.required("from", "date", readDate) };
    case "resumed":
      return present({
        ...base,
        kind,
        from: fields.required("from", "date", readDate),
        finish: fields.when(fields.has("remaining"), "finish", "date", readDate),
        remaining: fields.when(fields.has("finish"), "remaining", "positive", readPositive),
      });
    case "returned": {
      const date = fields.required("date", "date", readDate);
      const choice = fields.required("choice", "choice", oneOf(returnChoices));
      if (choice !== "spread" && choice !== "moveFinish") return { ...base, kind, date, choice };
      return {
        ...base,
        kind,
        date,
        choice,
        finish: fields.required("finish", "date", readDate),
        remaining: fields.required("remaining", "positive", readPositive),
      };
    }
    case "ended":
      return { ...base, kind, date: fields.required("date", "date", readDate) };
  }
}

/** An event's wire form: what a client stores and sends, and what `parseJournalEvent` reads back. */
export function journalEventWire(event: JournalEvent): Record<string, unknown> {
  const wire: Record<string, unknown> = {};
  for (const [name, value] of Object.entries(event) as [string, unknown][]) {
    if (name === "reminder") {
      wire[name] = value === "off" ? "off" : wallTimeText(value as WallTime);
    } else if (typeof value === "object" && value !== null && !Array.isArray(value)) {
      wire[name] = civilDateText(value as CivilDate);
    } else {
      wire[name] = value;
    }
  }
  return wire;
}

/** The wire form with its keys in order, so two events compare by content. */
function canonicalText(event: JournalEvent): string {
  const wire = journalEventWire(event);
  return JSON.stringify(
    Object.keys(wire)
      .sort()
      .map((name) => [name, wire[name]]),
  );
}

// MARK: State

export type InertReason =
  | "noEnrollment"
  | "unknownPlan"
  | "unknownAssignment"
  | "wrongSlot"
  | "notPermitted"
  | "noTarget"
  | "ended"
  | "noEffect";

export type SlotState = "unread" | "read" | "partlyRead" | "skipped";

/** One thing a reader can mark: an assignment, and on a calendar plan the date it is appointed to. */
export interface Slot {
  readonly assignment: number;
  readonly appointed?: CivilDate;
}

/** What a settled slot's last active marking event says. */
export interface SlotMark extends Slot {
  readonly state: Exclude<SlotState, "unread">;
  /** The day the reading happened. */
  readonly date: CivilDate;
  readonly event: EventID;
  readonly verses?: string;
}

/** The reader's arrangement for following a plan, on one date. */
export interface Arrangement {
  readonly behavior: Behavior;
  readonly start: CivilDate;
  readonly readingDays: readonly number[];
  readonly limit?: number;
  readonly reminder?: WallTime;
}

/** Paused days: from `from` up to, not including, `until`; with no `until` they run on. */
export interface Pause {
  readonly from: CivilDate;
  readonly until?: CivilDate;
}

/** An enrollment's events other than its `enrolled` event, marks and undos. */
export type ArrangingEvent = ChangedEvent | PausedEvent | ResumedEvent | ReturnedEvent | EndedEvent;

const markStates = {
  completed: "read",
  partlyCompleted: "partlyRead",
  skipped: "skipped",
} as const;

const slotKey = (slot: Slot) =>
  slot.appointed ? `${slot.assignment}@${civilDateText(slot.appointed)}` : `${slot.assignment}`;

const isMark = (event: JournalEvent): event is MarkingEvent => event.kind in markStates;

const onOrBefore = (a: CivilDate, b: CivilDate) => compareCivilDates(a, b) <= 0;

/** The behavior arranged for a date, from the active events given. */
function behaviorOn(
  enrolled: EnrolledEvent,
  arranging: Iterable<ArrangingEvent>,
  date: CivilDate,
): Behavior {
  let behavior = enrolled.behavior;
  for (const event of arranging) {
    if (event.kind === "changed" && event.behavior && onOrBefore(event.from, date)) {
      behavior = event.behavior;
    }
  }
  return behavior;
}

/** The start date, from the active events given. */
function startOf(enrolled: EnrolledEvent, arranging: Iterable<ArrangingEvent>): CivilDate {
  let start = enrolled.start;
  for (const event of arranging) if (event.kind === "changed" && event.start) start = event.start;
  return start;
}

/** One reader's following of one plan version, as the journal's active events add up to it. */
export class Enrollment {
  readonly id: EventID;
  readonly plan: PlanVersion;
  readonly enrolled: EnrolledEvent;
  /** Its active marking events, in journal order. */
  readonly marks: readonly MarkingEvent[];
  /** Its other active events, in journal order. */
  readonly arranging: readonly ArrangingEvent[];
  readonly start: CivilDate;
  /** The date the reader stopped, when they have. */
  readonly ended: CivilDate | undefined;
  /** In order of date, with none overlapping. */
  readonly pauses: readonly Pause[];
  /** Every settled slot, in reading order and then by appointed date. */
  readonly settled: readonly SlotMark[];
  private readonly slots: ReadonlyMap<string, SlotMark>;

  constructor(
    enrolled: EnrolledEvent,
    plan: PlanVersion,
    marks: readonly MarkingEvent[],
    arranging: readonly ArrangingEvent[],
  ) {
    this.id = enrolled.enrollment;
    this.plan = plan;
    this.enrolled = enrolled;
    this.marks = marks;
    this.arranging = arranging;
    this.start = startOf(enrolled, arranging);
    this.ended = arranging.findLast((event) => event.kind === "ended")?.date;

    const slots = new Map<string, SlotMark>();
    for (const mark of marks) {
      slots.set(
        slotKey(mark),
        present({
          assignment: mark.assignment,
          appointed: mark.appointed,
          state: markStates[mark.kind],
          date: mark.date,
          event: mark.id,
          verses: mark.verses,
        }),
      );
    }
    this.slots = slots;
    const positions = assignmentPositions(plan);
    const place = (mark: SlotMark) => positions.get(mark.assignment) ?? 0;
    this.settled = [...slots.values()].sort(
      (a, b) =>
        place(a) - place(b) ||
        (a.appointed && b.appointed ? compareCivilDates(a.appointed, b.appointed) : 0),
    );
    this.pauses = pausesOf(arranging);
  }

  /** A slot's state: what its last active marking event says, or unread. */
  state(slot: Slot): SlotState {
    return this.slots.get(slotKey(slot))?.state ?? "unread";
  }

  /** The arrangement on a date. */
  arrangement(date: CivilDate): Arrangement {
    let readingDays = this.enrolled.readingDays;
    let limit = this.enrolled.limit;
    let reminder = this.enrolled.reminder;
    for (const event of this.arranging) {
      if (event.kind !== "changed" || !onOrBefore(event.from, date)) continue;
      readingDays = event.readingDays ?? readingDays;
      limit = event.limit ?? limit;
      reminder = event.reminder ?? reminder;
    }
    return present({
      behavior: behaviorOn(this.enrolled, this.arranging, date),
      start: this.start,
      readingDays,
      limit,
      reminder: reminder === "off" ? undefined : reminder,
    });
  }

  /** Whether a date is a paused day. */
  isPaused(date: CivilDate): boolean {
    return this.pauses.some(
      (pause) =>
        onOrBefore(pause.from, date) && (!pause.until || compareCivilDates(date, pause.until) < 0),
    );
  }
}

/** The paused days the active `paused` and `resumed` events give, merged and in order. */
function pausesOf(arranging: readonly ArrangingEvent[]): Pause[] {
  const ranges: Pause[] = [];
  arranging.forEach((event, index) => {
    if (event.kind !== "paused") return;
    const resumed = arranging.slice(index + 1).find((later) => later.kind === "resumed");
    if (!resumed) ranges.push({ from: event.from });
    else if (compareCivilDates(event.from, resumed.from) < 0) {
      ranges.push({ from: event.from, until: resumed.from });
    }
  });
  ranges.sort((a, b) => compareCivilDates(a.from, b.from));
  const merged: Pause[] = [];
  for (const range of ranges) {
    const last = merged.at(-1);
    if (!last) merged.push(range);
    else if (!last.until) continue;
    else if (compareCivilDates(range.from, last.until) > 0) merged.push(range);
    else if (!range.until) merged[merged.length - 1] = { from: last.from };
    else if (compareCivilDates(range.until, last.until) > 0) {
      merged[merged.length - 1] = { from: last.from, until: range.until };
    }
  }
  return merged;
}

/** An enrollment while the fold is under way. */
interface Working {
  readonly plan: PlanVersion;
  readonly enrolled: EnrolledEvent;
  readonly positions: Map<number, number>;
  /** Indices, in journal order, of its marking events that are not inert. */
  readonly marks: number[];
  /** Indices of its other events that are not inert, undos apart. */
  readonly arranging: number[];
}

/**
 * The journal, folded (docs/engine.md, "The fold"): its events in journal
 * order, each once; the inert ones and why; which are active; and each
 * enrollment's state.
 */
export class Journal {
  /** In journal order, each id once. */
  readonly events: readonly JournalEvent[];
  /** The events that can mean nothing, in journal order. */
  readonly inert: readonly { readonly event: EventID; readonly reason: InertReason }[];
  /** In the order of their `enrolled` events. */
  readonly enrollments: readonly Enrollment[];
  private readonly activeIDs: ReadonlySet<EventID>;

  /** Folds events against the plan versions given. Throws `JournalError` for two different events under one id. */
  constructor(events: readonly JournalEvent[], plans: readonly PlanVersion[]) {
    const sorted = [...events].sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
    const distinct: JournalEvent[] = [];
    for (const event of sorted) {
      const last = distinct.at(-1);
      if (last?.id !== event.id) distinct.push(event);
      else if (canonicalText(last) !== canonicalText(event)) {
        throw new JournalError("conflictingEvent", `two different events have the id ${event.id}`);
      }
    }

    const planOf = new Map(plans.map((plan) => [`${plan.id}@${plan.version}`, plan]));
    const indexOf = new Map<EventID, number>();
    const effective: boolean[] = [];
    const active: boolean[] = [];
    const undoers = new Map<number, number[]>();
    const working = new Map<EventID, Working>();
    const inert: { event: EventID; reason: InertReason }[] = [];

    const activeArranging = function* (enrollment: Working) {
      for (const index of enrollment.arranging) {
        if (active[index]) yield distinct[index] as ArrangingEvent;
      }
    };
    const lastActive = (enrollment: Working, ...kinds: EventKind[]) => {
      let found: ArrangingEvent | undefined;
      for (const event of activeArranging(enrollment))
        if (kinds.includes(event.kind)) found = event;
      return found;
    };
    const scheduledOn = (enrollment: Working, date: CivilDate, own?: Behavior) =>
      (own ?? behaviorOn(enrollment.enrolled, activeArranging(enrollment), date)) === "finish-date";

    /** Why an event can mean nothing, from the events before it alone. */
    const reasonFor = (event: JournalEvent): InertReason | undefined => {
      const enrollment = working.get(event.enrollment);
      if (event.kind === "enrolled") {
        if (enrollment) return "noEffect";
        const plan = planOf.get(`${event.plan}@${event.version}`);
        if (!plan) return "unknownPlan";
        if (!plan.behaviors.includes(event.behavior)) return "notPermitted";
        if (event.behavior !== "finish-date" && (event.finish || event.limit !== undefined)) {
          return "notPermitted";
        }
        return undefined;
      }
      if (!enrollment) return "noEnrollment";
      const stopped = lastActive(enrollment, "ended");
      if (stopped && !(event.kind === "undone" && event.target === stopped.id)) return "ended";
      switch (event.kind) {
        case "completed":
        case "partlyCompleted":
        case "skipped": {
          if (!enrollment.positions.has(event.assignment)) return "unknownAssignment";
          if (enrollment.plan.schedule !== "day-of-month") {
            return event.appointed ? "wrongSlot" : undefined;
          }
          const start = startOf(enrollment.enrolled, activeArranging(enrollment));
          return event.appointed &&
            event.appointed.day === event.assignment &&
            onOrBefore(start, event.appointed)
            ? undefined
            : "wrongSlot";
        }
        case "undone": {
          const target = indexOf.get(event.target);
          const found = target === undefined ? undefined : distinct[target];
          return found &&
            effective[target as number] &&
            found.enrollment === event.enrollment &&
            found.kind !== "enrolled"
            ? undefined
            : "noTarget";
        }
        case "changed": {
          const fields = [
            event.start,
            event.readingDays,
            event.behavior,
            event.finish,
            event.limit,
            event.reminder,
          ];
          if (fields.every((field) => field === undefined)) return "noEffect";
          if (event.behavior && !enrollment.plan.behaviors.includes(event.behavior)) {
            return "notPermitted";
          }
          return (event.finish || event.limit !== undefined) &&
            !scheduledOn(enrollment, event.from, event.behavior)
            ? "notPermitted"
            : undefined;
        }
        case "paused":
          return lastActive(enrollment, "paused", "resumed")?.kind === "paused"
            ? "noEffect"
            : undefined;
        case "resumed":
          if (lastActive(enrollment, "paused", "resumed")?.kind !== "paused") return "noEffect";
          return event.finish && !scheduledOn(enrollment, event.from) ? "notPermitted" : undefined;
        case "returned": {
          const behavior = behaviorOn(enrollment.enrolled, activeArranging(enrollment), event.date);
          const fits =
            event.choice === "rejoin"
              ? behavior === "calendar"
              : event.choice === "continue"
                ? behavior !== "calendar"
                : behavior === "finish-date";
          return fits ? undefined : "notPermitted";
        }
        case "ended":
          return undefined;
      }
    };

    /** Whether an event is active: no active undo targets it. Follows the change down the chain. */
    const refresh = (index: number) => {
      let at: number | undefined = index;
      while (at !== undefined) {
        const now = !(undoers.get(at) ?? []).some((undo) => active[undo]);
        if (now === active[at]) return;
        active[at] = now;
        const event: JournalEvent | undefined = distinct[at];
        at = event?.kind === "undone" ? indexOf.get(event.target) : undefined;
      }
    };

    const order: Working[] = [];
    distinct.forEach((event, index) => {
      const reason = reasonFor(event);
      indexOf.set(event.id, index);
      effective[index] = reason === undefined;
      active[index] = reason === undefined;
      if (reason !== undefined) {
        inert.push({ event: event.id, reason });
        return;
      }
      if (event.kind === "enrolled") {
        const plan = planOf.get(`${event.plan}@${event.version}`) as PlanVersion;
        const enrollment: Working = {
          plan,
          enrolled: event,
          positions: assignmentPositions(plan),
          marks: [],
          arranging: [],
        };
        working.set(event.enrollment, enrollment);
        order.push(enrollment);
        return;
      }
      const enrollment = working.get(event.enrollment) as Working;
      if (event.kind === "undone") {
        const target = indexOf.get(event.target) as number;
        undoers.set(target, [...(undoers.get(target) ?? []), index]);
        refresh(target);
      } else if (isMark(event)) enrollment.marks.push(index);
      else enrollment.arranging.push(index);
    });

    this.events = distinct;
    this.inert = inert;
    this.activeIDs = new Set(distinct.filter((_, index) => active[index]).map((event) => event.id));
    this.enrollments = order.map(
      (enrollment) =>
        new Enrollment(
          enrollment.enrolled,
          enrollment.plan,
          enrollment.marks
            .filter((index) => active[index])
            .map((index) => distinct[index] as MarkingEvent),
          [...activeArranging(enrollment)],
        ),
    );
  }

  /** Whether an event is active: in the journal, not inert, and not undone. */
  isActive(id: EventID): boolean {
    return this.activeIDs.has(id);
  }
}

/**
 * Reads events from their wire form and folds them. Every event is checked
 * before any is folded, so a malformed event refuses the journal whatever
 * else is wrong with it.
 */
export function foldJournal(events: readonly unknown[], plans: readonly PlanVersion[]): Journal {
  return new Journal(
    events.map((event, index) => parseJournalEvent(event, index + 1)),
    plans,
  );
}
