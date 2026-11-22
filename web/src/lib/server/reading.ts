// The reader's own record, worked out on the server from what the browser
// sends and kept nowhere (BUILD.md D39, P8.10c; docs/decisions.md E52): the
// journal the browser keeps in IndexedDB is folded with the served catalog,
// Today is answered by the domain module, and a new event is made by the
// same rules the app's are. Nothing here is stored, logged or cached, and
// nothing here restates a reading rule. Server-only.
import {
  assignmentPositions,
  bibleLink,
  bibleTranslation,
  chaptersPassage,
  CivilDateError,
  civilDateText,
  daysInMonth,
  eventIDMilliseconds,
  foldJournal,
  Journal,
  JournalError,
  journalEventWire,
  makeEventID,
  parseCivilDate,
  ReferenceFormatter,
  today as todayOf,
  type Behavior,
  type CivilDate,
  type EventID,
  type JournalEvent,
  type MarkKind,
  type NamingConvention,
  type Reading,
  type TodayStatus,
} from "#lib/domain/index.ts";
import { placeInPrint, referenceOf, type Reference } from "#lib/reference.ts";
import { listText, text } from "#lib/strings.ts";
import { dayText } from "./catalog/present.ts";
import type { ServedCatalog } from "./catalog/read.ts";

/** Why a request is refused, in a word the browser's script can act on. */
export class ReadingRequestError extends Error {
  override name = "ReadingRequestError";
}

/** The most events one request may carry; far beyond a decade of daily reading. */
const mostEvents = 20_000;

/** The journal and the reader's date, from a request's JSON body. */
export interface JournalRequest {
  readonly journal: Journal;
  readonly today: CivilDate;
}

function record(value: unknown): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new ReadingRequestError("the request is not an object");
  }
  return value as Record<string, unknown>;
}

function date(value: unknown, field: string): CivilDate {
  if (typeof value !== "string") throw new ReadingRequestError(`${field} is not a date`);
  try {
    return parseCivilDate(value);
  } catch (error) {
    if (error instanceof CivilDateError) throw new ReadingRequestError(`${field} is not a date`);
    throw error;
  }
}

/** Reads `events` and `today` from a body, and folds the events with the catalog. */
export function journalRequest(body: unknown, catalog: ServedCatalog): JournalRequest {
  const fields = record(body);
  const events = fields["events"];
  if (!Array.isArray(events) || events.length > mostEvents) {
    throw new ReadingRequestError("events is not a list of events");
  }
  try {
    return {
      journal: foldJournal(
        events,
        catalog.plans.map((entry) => entry.plan),
      ),
      today: date(fields["today"], "today"),
    };
  } catch (error) {
    if (error instanceof JournalError) throw new ReadingRequestError(error.message);
    throw error;
  }
}

/** How the reader reads, from their settings (tests/fixtures/settings.json). */
export interface ReadingOptions {
  readonly convention?: NamingConvention;
  readonly way?: "physicalBible" | "youVersion" | "otherApp";
  /** Bible.com's number for the reader's translation; absent until chosen. */
  readonly translation?: number;
}

/** One reading on a Today card. */
export interface TodayReading {
  /** "Gospels at your pace — Reading 12", or "— Day 21" by the date. */
  readonly label: string;
  readonly reference: Reference;
  readonly assignment: number;
  readonly appointed?: string;
  /** For a physical Bible, where each passage is in print. */
  readonly print?: readonly string[];
  /** For YouVersion: the Bible.com address, and where it opens when not the whole reading. */
  readonly open?: { readonly href: string; readonly note?: string };
  /** For YouVersion with no translation chosen yet. */
  readonly chooseTranslation?: true;
}

/** How a reading is opened or found, by the way the reader reads (P8.5, P8.6). */
function wayIn(
  reading: Reading,
  names: ReferenceFormatter,
  options: ReadingOptions,
): Pick<TodayReading, "print" | "open" | "chooseTranslation"> {
  switch (options.way ?? "physicalBible") {
    case "physicalBible":
      return { print: reading.passages.map((passage) => placeInPrint(passage, names)) };
    case "youVersion": {
      const translation =
        options.translation === undefined ? undefined : bibleTranslation(options.translation);
      if (!translation) return { chooseTranslation: true };
      const link = bibleLink(reading, translation, names.versification);
      if (link.isWholeReading) return { open: { href: link.address } };
      const chapter = names.reading({
        passages: [
          chaptersPassage(
            link.book,
            { first: link.chapter, last: link.chapter },
            names.versification,
          ),
        ],
      });
      return { open: { href: link.address, note: text("today.opens-at", { chapter }) } };
    }
    default:
      return {};
  }
}

/** One plan's day on Today (docs/product.md, Today). */
export interface TodayCard {
  readonly enrollment: EventID;
  readonly plan: string;
  readonly status: TodayStatus;
  /** The day in words, when there is no reading to read now. */
  readonly message?: string;
  readonly readings: readonly TodayReading[];
  /** On a short month's last day, the days it does not appoint. */
  readonly note?: string;
  /** The last mark made today, to offer Undo for. */
  readonly lastMark?: { readonly event: EventID; readonly message: string };
}

function formatter(catalog: ServedCatalog, convention: NamingConvention): ReferenceFormatter {
  return new ReferenceFormatter(catalog.registry, catalog.versification, convention);
}

function statusText(status: TodayStatus, start: CivilDate): string | undefined {
  switch (status) {
    case "upcoming":
      return text("today.upcoming", { date: dayText(start) });
    case "done":
      return text("today.done");
    case "open":
      return text("today.open");
    case "rest":
      return text("today.rest");
    case "paused":
      return text("today.paused");
    case "finished":
      return text("today.finished");
    default:
      return undefined;
  }
}

function markMessage(kind: MarkKind, reference: string): string {
  switch (kind) {
    case "completed":
      return text("today.marked-read", { reference });
    case "partlyCompleted":
      return text("today.marked-part", { reference });
    case "skipped":
      return text("today.marked-skipped", { reference });
  }
}

/** Today for every plan the reader follows and has not ended, in the order started. */
export function todayCards(
  catalog: ServedCatalog,
  journal: Journal,
  date: CivilDate,
  options: ReadingOptions = {},
): TodayCard[] {
  const names = formatter(catalog, options.convention ?? "common");
  return journal.enrollments
    .filter((enrollment) => enrollment.ended === undefined)
    .map((enrollment) => {
      const entry = catalog.plans.find((plan) => plan.id === enrollment.plan.id);
      const title = entry?.title ?? enrollment.plan.id;
      const day = todayOf(enrollment, date);
      const positions = assignmentPositions(enrollment.plan);
      const readingOf = (assignment: number) =>
        enrollment.plan.assignments.find((candidate) => candidate.id === assignment)?.reading;
      const readings =
        day.status === "reading"
          ? day.readings.flatMap((slot) => {
              const reading = readingOf(slot.assignment);
              if (!reading) return [];
              const label = slot.appointed
                ? text("today.label-day", { plan: title, day: String(slot.appointed.day) })
                : text("today.label-reading", {
                    plan: title,
                    position: String(positions.get(slot.assignment) ?? slot.assignment),
                  });
              return [
                {
                  label,
                  reference: referenceOf(reading, names),
                  assignment: slot.assignment,
                  ...(slot.appointed ? { appointed: civilDateText(slot.appointed) } : {}),
                  ...wayIn(reading, names, options),
                },
              ];
            })
          : [];
      const notAppointed = day.calendar?.notAppointed ?? [];
      const last = journal.events.findLast(
        (event) =>
          event.enrollment === enrollment.id &&
          (event.kind === "completed" ||
            event.kind === "partlyCompleted" ||
            event.kind === "skipped") &&
          civilDateText(event.date) === civilDateText(date) &&
          journal.isActive(event.id),
      );
      const lastReading =
        last && "assignment" in last ? readingOf(last.assignment as number) : undefined;
      const message = statusText(day.status, enrollment.start);
      return {
        enrollment: enrollment.id,
        plan: title,
        status: day.status,
        ...(message ? { message } : {}),
        readings,
        ...(notAppointed.length > 0
          ? {
              note: text("today.short-month", {
                days: String(daysInMonth(date.month, date.year)),
                list: listText(notAppointed.map(String)),
              }),
            }
          : {}),
        ...(last && lastReading
          ? {
              lastMark: {
                event: last.id,
                message: markMessage(
                  last.kind as MarkKind,
                  referenceOf(lastReading, names).display,
                ),
              },
            }
          : {}),
      };
    });
}

// MARK: Making events

/** The instant as the journal records it: `YYYY-MM-DDTHH:MM:SSZ`. */
function instantText(now: Date): string {
  return now.toISOString().replace(/\.\d{3}Z$/, "Z");
}

function zoneOf(value: unknown): string {
  return typeof value === "string" && /^[A-Za-z0-9/_+-]{1,64}$/.test(value) ? value : "UTC";
}

/** A new UUIDv7 id at or after `milliseconds`, with random bytes from the platform. */
function newID(milliseconds: number): EventID {
  const id = makeEventID(milliseconds, [...crypto.getRandomValues(new Uint8Array(10))]);
  if (id === undefined) throw new ReadingRequestError("no id can be made for this time");
  return id;
}

function integer(value: unknown, field: string, low: number, high: number): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < low || value > high) {
    throw new ReadingRequestError(`${field} is out of range`);
  }
  return value;
}

/**
 * The events a reader's action makes (docs/engine.md, "The journal"), each
 * checked by folding the journal with it: starting a plan, marking a
 * reading, or taking a mark back. An action whose event would mean nothing
 * is refused. Returns the new events in their wire form.
 */
export function newEvents(
  body: unknown,
  catalog: ServedCatalog,
  now: Date,
): Record<string, unknown>[] {
  const fields = record(body);
  const { journal, today } = journalRequest(body, catalog);
  const action = record(fields["action"]);
  const at = instantText(now);
  const zone = zoneOf(fields["zone"]);
  const device = "Web";
  let made: JournalEvent[];

  switch (action["kind"]) {
    case "enroll": {
      const entry = catalog.plans.find((plan) => plan.id === action["plan"]);
      if (!entry) throw new ReadingRequestError("there is no such plan");
      const behavior = action["behavior"] as Behavior;
      if (!entry.plan.behaviors.includes(behavior)) {
        throw new ReadingRequestError("the plan does not permit that behavior");
      }
      const readingDays = action["readingDays"];
      if (
        !Array.isArray(readingDays) ||
        readingDays.length === 0 ||
        readingDays.some(
          (day, index) =>
            typeof day !== "number" ||
            !Number.isInteger(day) ||
            day < 1 ||
            day > 7 ||
            (index > 0 && day <= (readingDays[index - 1] as number)),
        )
      ) {
        throw new ReadingRequestError("readingDays are not weekdays in order");
      }
      const start = date(action["start"], "start");
      const enrollment = newID(now.getTime());
      const event = {
        id: newID(eventIDMilliseconds(enrollment) + 1),
        enrollment,
        at,
        zone,
        device,
        kind: "enrolled",
        plan: entry.id,
        version: entry.version,
        behavior,
        start,
        readingDays: readingDays as number[],
        ...(behavior === "finish-date"
          ? {
              finish: date(action["finish"], "finish"),
              limit: integer(action["limit"], "limit", 1, 10),
            }
          : {}),
      } as JournalEvent;
      made = [event];
      break;
    }
    case "mark":
    case "undo": {
      const enrollment = journal.enrollments.find(
        (candidate) => candidate.id === action["enrollment"],
      );
      if (!enrollment) throw new ReadingRequestError("there is no such plan in the journal");
      const latest = journal.events
        .filter((event) => event.enrollment === enrollment.id)
        .map((event) => eventIDMilliseconds(event.id))
        .reduce((a, b) => Math.max(a, b), eventIDMilliseconds(enrollment.id));
      const record = { enrollment: enrollment.id, at, zone, device };
      const id = newID(Math.max(now.getTime(), latest + 1));
      if (action["kind"] === "undo") {
        const target = action["target"];
        if (typeof target !== "string") throw new ReadingRequestError("target is not an event");
        made = [{ ...record, id, kind: "undone", target } as JournalEvent];
      } else {
        const kind = action["mark"];
        if (kind !== "completed" && kind !== "partlyCompleted" && kind !== "skipped") {
          throw new ReadingRequestError("mark is not a kind of mark");
        }
        const appointed = action["appointed"];
        made = [
          {
            ...record,
            id,
            kind,
            assignment: integer(action["assignment"], "assignment", 1, 100_000),
            date: today,
            ...(appointed === undefined ? {} : { appointed: date(appointed, "appointed") }),
          } as JournalEvent,
        ];
      }
      break;
    }
    default:
      throw new ReadingRequestError("action is not one Day by Word knows");
  }

  // The new events must mean something in this journal: an action on a
  // reading already settled, or an undo of nothing, is refused here rather
  // than kept as an inert event.
  const after = new Journal([...journal.events, ...made], journal.plans);
  const inert = after.inert.find((entry) => made.some((event) => event.id === entry.event));
  if (inert) throw new ReadingRequestError(`the change means nothing: ${inert.reason}`);
  return made.map(journalEventWire);
}
