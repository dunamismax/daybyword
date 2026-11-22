// The reader's own record, worked out on the server from what the browser
// sends and kept nowhere (BUILD.md D39, P8.10c; docs/decisions.md E52): the
// journal the browser keeps in IndexedDB is folded with the served catalog,
// Today is answered by the domain module, and a new event is made by the
// same rules the app's are. Nothing here is stored, logged or cached, and
// nothing here restates a reading rule. Server-only.
import {
  assignmentPositions,
  bibleLink,
  bookName,
  celebrations as celebrationsOn,
  coverage,
  coverageByBook,
  bibleTranslation,
  chaptersPassage,
  CivilDateError,
  civilDateText,
  daysInMonth,
  eventIDMilliseconds,
  foldJournal,
  isEventID,
  Journal,
  JournalError,
  journalEventWire,
  makeEventID,
  parseCivilDate,
  isFinished,
  previewing,
  progressCounts,
  recentDays,
  recordSlots,
  streak,
  ReferenceFormatter,
  weekday,
  workload,
  today as todayOf,
  welcome as welcomeOf,
  welcomeAnswer,
  type Behavior,
  type BookCoverage,
  type CivilDate,
  type Enrollment,
  type EventID,
  type JournalEvent,
  type MarkKind,
  type NamingConvention,
  type Reading,
  type ReturnChoice,
  type TodayStatus,
} from "#lib/domain/index.ts";
import { placeInPrint, referenceOf, type Reference } from "#lib/reference.ts";
import { listText, minutesRangeText, text } from "#lib/strings.ts";
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
  /** The event the reader's last action in this tab made, to offer Undo (or Redo) for. */
  readonly lastAction?: EventID;
  /** Whether Progress shows the reading days read in a row (D17); off unless the reader turns it on. */
  readonly streak?: boolean;
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

/** A choice after a gap, with what it would change, worked out before anything does (P8.7). */
export interface WelcomeChoice {
  readonly choice: ReturnChoice;
  readonly title: string;
  readonly effect: string;
}

/** One plan's day on Today (docs/product.md, Today). */
export interface TodayCard {
  /** After a gap: the welcome and its choices, first on the card. */
  readonly welcome?: readonly WelcomeChoice[];
  readonly enrollment: EventID;
  readonly plan: string;
  readonly status: TodayStatus;
  /** The day in words, when there is no reading to read now. */
  readonly message?: string;
  readonly readings: readonly TodayReading[];
  /** On a short month's last day, the days it does not appoint. */
  readonly note?: string;
  /** What this plan's day quietly notices, in words (P11.2). */
  readonly celebrations?: readonly string[];
  /** The reader's last action, or else the last mark made today, to take back. */
  readonly lastMark?: {
    readonly event: EventID;
    readonly message: string;
    /** Whether taking it back is a Redo: the last action was itself an undo. */
    readonly redo?: true;
  };
  /** The earliest date an earlier day can be logged for: the plan's start. */
  readonly start: string;
  /** Today, the latest date an earlier day can be logged for. */
  readonly today: string;
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

function markMessage(kind: MarkKind, reference: string, on?: CivilDate): string {
  switch (kind) {
    case "completed":
      return on
        ? text("today.marked-read-on", { reference, date: dayText(on) })
        : text("today.marked-read", { reference });
    case "partlyCompleted":
      return text("today.marked-part", { reference });
    case "skipped":
      return text("today.marked-skipped", { reference });
  }
}

/** Today's cards, and the week's rhythm when the reader kept it (P11.2). */
export interface TodayPage {
  readonly cards: readonly TodayCard[];
  readonly rhythm?: string;
}

/** Today's cards with what each plan's day quietly notices, and the week's rhythm. */
export function todayPage(
  catalog: ServedCatalog,
  journal: Journal,
  date: CivilDate,
  options: ReadingOptions = {},
): TodayPage {
  const noticed = celebrationsOn(journal, date, catalog.versification);
  const cards = todayCards(catalog, journal, date, options).map((card) => {
    const words = noticed.flatMap((celebration) => {
      if (celebration.kind === "keptRhythm" || celebration.enrollment !== card.enrollment)
        return [];
      switch (celebration.kind) {
        case "returned":
          return [text("celebration.returned")];
        case "finishedBook": {
          const book = catalog.registry.book(celebration.book);
          const name = book
            ? bookName(book, options.convention ?? "common").name
            : celebration.book;
          return [text("celebration.finished-book", { book: name })];
        }
        case "finishedPlan":
          return [text("celebration.finished-plan", { plan: card.plan })];
      }
    });
    return words.length > 0 ? { ...card, celebrations: words } : card;
  });
  return noticed.some((celebration) => celebration.kind === "keptRhythm")
    ? { cards, rhythm: text("celebration.kept-rhythm") }
    : { cards };
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
      const isMark = (event: JournalEvent) =>
        event.kind === "completed" || event.kind === "partlyCompleted" || event.kind === "skipped";
      // The reader's last action in this tab, when it is this plan's and
      // still stands; else the last mark made today (as the app offers).
      const action = journal.events.find(
        (event) =>
          event.id === options.lastAction &&
          event.enrollment === enrollment.id &&
          journal.isActive(event.id),
      );
      const last =
        action && (isMark(action) || action.kind === "undone")
          ? action
          : journal.events.findLast(
              (event) =>
                event.enrollment === enrollment.id &&
                isMark(event) &&
                "date" in event &&
                civilDateText(event.date as CivilDate) === civilDateText(date) &&
                journal.isActive(event.id),
            );
      const lastReading =
        last && "assignment" in last ? readingOf(last.assignment as number) : undefined;
      const lastMark =
        last?.kind === "undone"
          ? { event: last.id, message: text("today.undone"), redo: true as const }
          : last && lastReading && "date" in last
            ? {
                event: last.id,
                message: markMessage(
                  last.kind as MarkKind,
                  referenceOf(lastReading, names).display,
                  civilDateText(last.date as CivilDate) === civilDateText(date)
                    ? undefined
                    : (last.date as CivilDate),
                ),
              }
            : undefined;
      const message = statusText(day.status, enrollment.start);
      const welcome = welcomeChoices(journal, enrollment.id, date, (slot) => {
        const reading = readingOf(slot.assignment);
        return reading ? names.reading(reading) : undefined;
      });
      return {
        ...(welcome && welcome.length > 0 ? { welcome } : {}),
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
        ...(lastMark ? { lastMark } : {}),
        start: civilDateText(enrollment.start),
        today: civilDateText(date),
      };
    });
}

/**
 * The welcome's choices for an enrollment on `date`, each with its effect
 * found by folding the journal with that answer added (docs/engine.md,
 * "Returning after a break"): the same words the app's WelcomeBack uses.
 */
function welcomeChoices(
  journal: Journal,
  id: EventID,
  date: CivilDate,
  reference: (slot: { assignment: number }) => string | undefined,
): WelcomeChoice[] | undefined {
  const enrollment = journal.enrollments.find((candidate) => candidate.id === id);
  const offered = enrollment ? welcomeOf(enrollment, date) : undefined;
  if (!offered) return undefined;
  return offered.offers.flatMap((offer): WelcomeChoice[] => {
    const after = previewing(journal, welcomeAnswer(offer, date), id)?.enrollments.find(
      (candidate) => candidate.id === id,
    );
    if (!after) return [];
    const answered = todayOf(after, date);
    switch (offer.choice) {
      case "continue": {
        const next = answered.readings[0] ?? answered.next;
        const named = next ? reference(next) : undefined;
        const finish = answered.projection?.plan;
        const effect = [
          named ? text("welcome.next", { reference: named }) : text("welcome.nothing"),
          ...(finish ? [text("welcome.finish-at-pace", { date: dayText(finish) })] : []),
        ].join(" ");
        return [{ choice: offer.choice, title: text("welcome.continue"), effect }];
      }
      case "spread":
        if (!offer.finish || offer.most === undefined) return [];
        return [
          {
            choice: offer.choice,
            title: text("welcome.spread"),
            effect:
              offer.most === 1
                ? text("welcome.spread-one", { date: dayText(offer.finish) })
                : text("welcome.spread-other", {
                    most: String(offer.most),
                    date: dayText(offer.finish),
                  }),
          },
        ];
      case "moveFinish":
        if (!offer.finish) return [];
        return [
          {
            choice: offer.choice,
            title: text("welcome.move-finish"),
            effect: text("welcome.finish-moves", { date: dayText(offer.finish) }),
          },
        ];
      case "rejoin": {
        const appointment = answered.calendar?.appointment;
        const named = appointment ? reference(appointment) : undefined;
        return [
          {
            choice: offer.choice,
            title: text("welcome.rejoin"),
            effect: named
              ? text("welcome.rejoin-today", { reference: named })
              : text("welcome.rejoin-plain"),
          },
        ];
      }
    }
  });
}

// MARK: Progress

/** One of the seven days ending today, in words as well as a symbol (P8.12). */
export interface ProgressStripDay {
  readonly initial: string;
  readonly symbol: "✓" | "○" | "–";
  readonly label: string;
}

/** One plan's record: readings by state, the next reading, and its finish. */
/** One reading in a plan's history (P11.5): its state in words, and what can be done with it. */
export interface HistoryReading {
  /** "Reading 12", or the date a calendar reading is appointed to. */
  readonly label: string;
  readonly reference: string;
  /** "Read on Monday 1 March", "Part read on …", "Skipped on …", or "Not yet read". */
  readonly state: string;
  readonly assignment: number;
  readonly appointed?: string;
  /** The mark to take back, when the reading is settled. */
  readonly undo?: EventID;
  /** Whether it can be marked read here: a calendar slot, or a sequence's reading part read or skipped. */
  readonly markable: boolean;
}

/** Where a plan stands, for grouping Progress (P11.5): the archive keeps finished, paused and stopped plans apart. */
export type PlanGroup = "reading" | "paused" | "finished" | "stopped";

export interface PlanRecord {
  readonly enrollment: EventID;
  readonly plan: string;
  readonly group: PlanGroup;
  readonly ended: boolean;
  readonly counts: string;
  readonly others?: string;
  readonly finished: boolean;
  readonly next?: string;
  readonly finish?: string;
  /** Every reading of the record, with its state (P11.5). */
  readonly readings: readonly HistoryReading[];
  /** Every change, newest first, in words (P11.5). */
  readonly changes: readonly string[];
  /** The dates a reading can be marked on: from the plan's start to today. */
  readonly start: string;
  readonly today: string;
  /** What the reader can do with the plan itself (P11.5). */
  readonly actions: {
    readonly pause?: true;
    readonly resume?: true;
    readonly end?: true;
    /** The `ended` event to take back, to follow the plan again. */
    readonly restore?: EventID;
  };
}

const changedFields = [
  ["readingDays", "history.what-reading-days"],
  ["behavior", "history.what-behavior"],
  ["finish", "history.what-finish"],
  ["limit", "history.what-limit"],
  ["reminder", "history.what-reminder"],
  ["start", "history.what-start"],
] as const;

const returnTitles = {
  continue: "welcome.continue",
  spread: "welcome.spread",
  moveFinish: "welcome.move-finish",
  rejoin: "welcome.rejoin",
} as const;

/** One event of a plan in words, as History lists it; undefined for an event that means nothing. */
function changeText(
  event: JournalEvent,
  journal: Journal,
  readingOf: (assignment: number) => Reading | undefined,
  names: ReferenceFormatter,
): string | undefined {
  const reference = (assignment: number) => {
    const reading = readingOf(assignment);
    return reading ? names.reading(reading) : String(assignment);
  };
  switch (event.kind) {
    case "enrolled":
      return text("history.started", { date: dayText(event.start) });
    case "completed":
      return text("today.marked-read-on", {
        reference: reference(event.assignment),
        date: dayText(event.date),
      });
    case "partlyCompleted":
      return text("history.marked-part", {
        reference: reference(event.assignment),
        date: dayText(event.date),
      });
    case "skipped":
      return text("history.marked-skipped", {
        reference: reference(event.assignment),
        date: dayText(event.date),
      });
    case "undone": {
      const target = journal.events.find((candidate) => candidate.id === event.target);
      const change = target ? changeText(target, journal, readingOf, names) : undefined;
      return change ? text("history.took-back", { change }) : undefined;
    }
    case "changed": {
      const what = changedFields
        .filter(([field]) => event[field] !== undefined)
        .map(([, key]) => text(key));
      return text("history.changed", { what: listText(what), date: dayText(event.from) });
    }
    case "paused":
      return text("history.paused", { date: dayText(event.from) });
    case "resumed":
      return text("history.resumed", { date: dayText(event.from) });
    case "returned":
      return text("history.returned", {
        date: dayText(event.date),
        choice: text(returnTitles[event.choice]),
      });
    case "ended":
      return text("history.ended", { date: dayText(event.date) });
  }
}

/** What the reader can do with a plan from its History (P11.5). */
function planActions(
  journal: Journal,
  enrollment: Enrollment,
  date: CivilDate,
  finished: boolean,
): PlanRecord["actions"] {
  if (enrollment.ended !== undefined) {
    const ended = journal.events.findLast(
      (event) =>
        event.enrollment === enrollment.id && event.kind === "ended" && journal.isActive(event.id),
    );
    return ended ? { restore: ended.id } : {};
  }
  if (enrollment.isPaused(date)) return { resume: true, end: true };
  return finished ? { end: true } : { pause: true, end: true };
}

/** A plan's history (P11.5): every reading of the record with its state, and every change, newest first. */
function planHistory(
  journal: Journal,
  enrollment: Enrollment,
  date: CivilDate,
  names: ReferenceFormatter,
): Pick<PlanRecord, "readings" | "changes"> {
  const readingOf = (assignment: number) =>
    enrollment.plan.assignments.find((candidate) => candidate.id === assignment)?.reading;
  const positions = assignmentPositions(enrollment.plan);
  const calendar = enrollment.plan.schedule === "day-of-month";
  const marks = new Map(
    enrollment.settled.map((mark) => [
      `${mark.assignment}@${mark.appointed ? civilDateText(mark.appointed) : ""}`,
      mark,
    ]),
  );
  const readings = recordSlots(enrollment, date).map((slot): HistoryReading => {
    const mark = marks.get(
      `${slot.assignment}@${slot.appointed ? civilDateText(slot.appointed) : ""}`,
    );
    const reading = readingOf(slot.assignment);
    const state = !mark
      ? text("history.unread")
      : text(
          mark.state === "read"
            ? "history.read-on"
            : mark.state === "partlyRead"
              ? "history.part-on"
              : "history.skipped-on",
          { date: dayText(mark.date) },
        );
    return {
      label: slot.appointed
        ? dayText(slot.appointed)
        : text("history.reading", {
            position: String(positions.get(slot.assignment) ?? slot.assignment),
          }),
      reference: reading ? names.reading(reading) : String(slot.assignment),
      state,
      assignment: slot.assignment,
      ...(slot.appointed ? { appointed: civilDateText(slot.appointed) } : {}),
      ...(mark ? { undo: mark.event } : {}),
      markable: mark?.state !== "read" && (calendar || mark !== undefined),
    };
  });
  const inert = new Set(journal.inert.map((entry) => entry.event));
  const changes = journal.events
    .filter((event) => event.enrollment === enrollment.id && !inert.has(event.id))
    .flatMap((event) => {
      const change = changeText(event, journal, readingOf, names);
      return change ? [change] : [];
    })
    .reverse();
  return { readings, changes };
}

/** A book explored, named as the reader names books, with what of it was read (P11.4). */
export interface ExploredBook {
  readonly name: string;
  /** "98 of 1,533 verses · 3 chapters read in full · 1 chapter in part", or "All 85 verses". */
  readonly detail: string;
}

const grouped = (value: number) => new Intl.NumberFormat("en").format(value);

/** What of a book was read, in words: its verses, then its chapters whole and in part. */
function exploredText(book: BookCoverage): string {
  if (book.verses === book.of) return text("progress.verses-all", { total: grouped(book.of) });
  const parts = [
    text("progress.verses-of", { read: grouped(book.verses), total: grouped(book.of) }),
  ];
  if (book.wholeChapters === 1) parts.push(text("progress.chapters-whole-one"));
  else if (book.wholeChapters > 1) {
    parts.push(text("progress.chapters-whole", { count: String(book.wholeChapters) }));
  }
  if (book.partialChapters === 1) parts.push(text("progress.chapters-part-one"));
  else if (book.partialChapters > 1) {
    parts.push(text("progress.chapters-part", { count: String(book.partialChapters) }));
  }
  return parts.join(" · ");
}

export interface ProgressPage {
  readonly days: readonly ProgressStripDay[];
  readonly plans: readonly PlanRecord[];
  /** The books explored in any plan, in the Bible's order, each with its verses and chapters read in words (P11.1, P11.4). */
  readonly books: readonly ExploredBook[];
  /** The reading days read in a row, in words, when the reader asked for them and there are some (D17). */
  readonly inARow?: string;
}

const weekdayKeys = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
] as const;

/** Progress as the app shows it (P8.12): the week's strip and each plan's record. */
export function progressPage(
  catalog: ServedCatalog,
  journal: Journal,
  date: CivilDate,
  options: ReadingOptions = {},
): ProgressPage {
  const names = formatter(catalog, options.convention ?? "common");
  const days = recentDays(journal, date).map((day): ProgressStripDay => {
    const name = text(`weekday.${weekdayKeys[weekday(day.date) - 1] ?? "monday"}`);
    const when = dayText(day.date);
    return {
      initial: name.slice(0, 1),
      symbol: day.isRead ? "✓" : day.isReadingDay ? "○" : "–",
      label: day.isRead
        ? text("progress.day-read", { date: when })
        : day.isReadingDay
          ? text("progress.day-unread", { date: when })
          : text("progress.day-rest", { date: when }),
    };
  });
  const plans = journal.enrollments.map((enrollment): PlanRecord => {
    const entry = catalog.plans.find((plan) => plan.id === enrollment.plan.id);
    const counts = progressCounts(enrollment, date);
    const total = counts.read + counts.partlyRead + counts.skipped + counts.unread;
    const others = [
      ...(counts.partlyRead > 0
        ? [text("progress.part-read", { count: String(counts.partlyRead) })]
        : []),
      ...(counts.skipped > 0 ? [text("progress.skipped", { count: String(counts.skipped) })] : []),
    ];
    const day = todayOf(enrollment, date);
    const nextSlot = day.next ?? day.readings[0];
    const nextReading = nextSlot
      ? enrollment.plan.assignments.find((candidate) => candidate.id === nextSlot.assignment)
          ?.reading
      : undefined;
    const finish = day.schedule?.finish ?? day.projection?.plan;
    const finished = isFinished(enrollment);
    return {
      enrollment: enrollment.id,
      plan: entry?.title ?? enrollment.plan.id,
      group:
        enrollment.ended !== undefined
          ? "stopped"
          : finished
            ? "finished"
            : enrollment.isPaused(date)
              ? "paused"
              : "reading",
      ...planHistory(journal, enrollment, date, names),
      start: civilDateText(enrollment.start),
      today: civilDateText(date),
      actions: planActions(journal, enrollment, date, finished),
      ended: enrollment.ended !== undefined,
      counts:
        total === 1
          ? text("progress.read-of-one", { read: String(counts.read) })
          : text("progress.read-of", { read: String(counts.read), total: String(total) }),
      ...(others.length > 0 ? { others: others.join(" · ") } : {}),
      finished: isFinished(enrollment),
      ...(nextReading && !isFinished(enrollment)
        ? { next: text("progress.next", { reference: names.reading(nextReading) }) }
        : {}),
      ...(finish && !isFinished(enrollment) && enrollment.ended === undefined
        ? {
            finish: day.schedule
              ? text("progress.finish-date", { date: dayText(finish) })
              : text("welcome.finish-at-pace", { date: dayText(finish) }),
          }
        : {}),
    };
  });
  // Kept apart from each plan's record: reading in a book is not finishing a
  // plan, and finishing a plan is not reading these books whole.
  // Each verse once, however many plans or times it was read (P11.4).
  const explored = coverageByBook(
    coverage(journal, catalog.versification),
    catalog.versification,
  ).flatMap((covered) => {
    const book = catalog.registry.book(covered.book);
    return book
      ? [
          {
            name: bookName(book, options.convention ?? "common").name,
            detail: exploredText(covered),
          },
        ]
      : [];
  });
  // The streak, only when the reader turned it on (D17): small, in words,
  // and said only while there is one, never as something lost.
  const count = options.streak ? streak(journal, date) : 0;
  const inARow =
    count === 1
      ? text("progress.in-a-row-one")
      : count > 1
        ? text("progress.in-a-row", { count: String(count) })
        : undefined;
  return { days, plans, books: explored, ...(inARow ? { inARow } : {}) };
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

/** The `enrolled` event for a start action, checked against the catalog. */
function enrolledEvent(
  action: Record<string, unknown>,
  catalog: ServedCatalog,
  now: Date,
  zone: string,
): JournalEvent {
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
  return {
    id: newID(eventIDMilliseconds(enrollment) + 1),
    enrollment,
    at: instantText(now),
    zone,
    device: "Web",
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
}

/** A candidate enrollment's schedule on its first day: the finish date's load. */
function scheduleOf(journal: Journal, enrolled: JournalEvent & { start: CivilDate }) {
  const after = new Journal([...journal.events, enrolled], journal.plans);
  const enrollment = after.enrollments.find((candidate) => candidate.id === enrolled.enrollment);
  return enrollment ? todayOf(enrollment, enrolled.start).schedule : undefined;
}

/**
 * What a finish date asks, before the reader starts (docs/product.md,
 * "Starting a plan"; P8.2b): readings a day, the heaviest day's time, or,
 * when that is beyond the reader's limit, the later date that fits.
 */
export function startPreview(
  body: unknown,
  catalog: ServedCatalog,
  now: Date,
): { readonly text: string; readonly fits: boolean; readonly later?: string } | undefined {
  const fields = record(body);
  const { journal } = journalRequest(body, catalog);
  const action = record(fields["action"]);
  if (action["behavior"] !== "finish-date") return undefined;
  const enrolled = enrolledEvent(action, catalog, now, "UTC") as JournalEvent & {
    start: CivilDate;
    finish: CivilDate;
    limit: number;
  };
  if (civilDateText(enrolled.finish) < civilDateText(enrolled.start)) {
    throw new ReadingRequestError("the finish is before the start");
  }
  const schedule = scheduleOf(journal, enrolled);
  if (!schedule) return undefined;
  if (schedule.most > enrolled.limit && schedule.finishWithinLimit) {
    return {
      text: text("start.too-many", {
        finish: dayText(enrolled.finish),
        most: String(schedule.most),
        limit: String(enrolled.limit),
        later: dayText(schedule.finishWithinLimit),
      }),
      fits: false,
      later: civilDateText(schedule.finishWithinLimit),
    };
  }
  const days = String(schedule.scheduledDays);
  const load =
    schedule.least !== schedule.most
      ? text("start.load-range", {
          least: String(schedule.least),
          most: String(schedule.most),
          days,
        })
      : schedule.most === 1
        ? text("start.load-one", { days })
        : text("start.load-same", { most: String(schedule.most), days });
  const heaviest =
    schedule.heaviestWords === undefined
      ? undefined
      : text("start.heaviest", {
          minutes: minutesRangeText(workload(schedule.heaviestWords).minutes),
        });
  return { text: heaviest ? `${load} ${heaviest}` : load, fits: schedule.most <= enrolled.limit };
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
      made = [enrolledEvent(action, catalog, now, zone)];
      const enrolled = made[0] as JournalEvent & { kind: "enrolled"; start: CivilDate };
      // A finish date that needs more readings a day than the reader allows
      // is refused; the start page shows why, and the later date that fits.
      const schedule = scheduleOf(journal, enrolled);
      if (schedule && schedule.most > (schedule.limit ?? Infinity)) {
        throw new ReadingRequestError("the finish date needs more readings a day than the limit");
      }
      break;
    }
    case "mark":
    case "undo":
    case "return":
    case "pause":
    case "resume":
    case "end": {
      const enrollment = journal.enrollments.find(
        (candidate) => candidate.id === action["enrollment"],
      );
      if (!enrollment) throw new ReadingRequestError("there is no such plan in the journal");
      const latest = journal.events
        .filter((event) => event.enrollment === enrollment.id)
        .map((event) => eventIDMilliseconds(event.id))
        .reduce((a, b) => Math.max(a, b), eventIDMilliseconds(enrollment.id));
      const record = { enrollment: enrollment.id, at, zone, device };
      // A mark made offline comes with the id the browser made for it then
      // (P8.11, E53), so sending it twice changes nothing.
      const proposed = action["id"];
      if (proposed !== undefined && (typeof proposed !== "string" || !isEventID(proposed))) {
        throw new ReadingRequestError("id is not an event id");
      }
      if (typeof proposed === "string" && journal.events.some((event) => event.id === proposed)) {
        return [];
      }
      const id =
        typeof proposed === "string" ? proposed : newID(Math.max(now.getTime(), latest + 1));
      if (action["kind"] === "pause" || action["kind"] === "resume") {
        // Paused from today, or resumed today (P11.5); the engine refuses
        // pausing what is paused and resuming what is not.
        made = [{ ...record, id, kind: `${action["kind"]}d`, from: today } as JournalEvent];
      } else if (action["kind"] === "end") {
        // The reader stops following the plan today; its record is kept.
        made = [{ ...record, id, kind: "ended", date: today } as JournalEvent];
      } else if (action["kind"] === "return") {
        // The answer to the welcome the engine offers today, and no other.
        const offer = welcomeOf(enrollment, today)?.offers.find(
          (candidate) => candidate.choice === action["choice"],
        );
        if (!offer) throw new ReadingRequestError("that choice is not offered today");
        made = [{ ...record, id, ...welcomeAnswer(offer, today) } as JournalEvent];
      } else if (action["kind"] === "undo") {
        const target = action["target"];
        if (typeof target !== "string") throw new ReadingRequestError("target is not an event");
        made = [{ ...record, id, kind: "undone", target } as JournalEvent];
      } else {
        const kind = action["mark"];
        if (kind !== "completed" && kind !== "partlyCompleted" && kind !== "skipped") {
          throw new ReadingRequestError("mark is not a kind of mark");
        }
        // An earlier day is logged on the date it happened, never as today
        // (docs/product.md, "Marking honestly"): from the start to today.
        const on = action["date"] === undefined ? today : date(action["date"], "date");
        if (
          civilDateText(on) > civilDateText(today) ||
          civilDateText(on) < civilDateText(enrollment.start)
        ) {
          throw new ReadingRequestError("date is not between the start and today");
        }
        // On a calendar plan, an earlier day's reading is that date's own,
        // unless the slot is named (History marks a slot on the date chosen).
        const calendar =
          enrollment.plan.schedule === "day-of-month" &&
          action["date"] !== undefined &&
          action["appointed"] === undefined;
        const appointed = calendar ? civilDateText(on) : action["appointed"];
        made = [
          {
            ...record,
            id,
            kind,
            assignment: calendar ? on.day : integer(action["assignment"], "assignment", 1, 100_000),
            date: on,
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
