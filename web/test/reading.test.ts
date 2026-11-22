// The web's own record, worked out on the server from what the browser
// sends (BUILD.md P8.10c, docs/decisions.md E52): starting a plan, Today's
// cards, marking and undoing, and the requests that are refused. The plans
// are invented (tests/fixtures/README.md); the scripture is the catalog's.
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  BookRegistry,
  eventIDMilliseconds,
  makeEventID,
  parseReading,
  Versification,
  type PlanVersion,
} from "#lib/domain/index.ts";
import type { CatalogPlan, ServedCatalog } from "#lib/server/catalog/read.ts";
import {
  calendarFor,
  journalRequest,
  newEvents,
  progressPage,
  startPreview,
  ReadingRequestError,
  todayCards,
  todayPage,
} from "#lib/server/reading.ts";

const repository = new URL("../../", import.meta.url);
const read = (path: string) => readFileSync(new URL(path, repository), "utf8");
const registry = new BookRegistry(read("catalog/scripture/books.json"));
const english = new Versification("english", read("catalog/scripture/versification/english.tsv"));

function plan(
  id: string,
  title: string,
  schedule: PlanVersion["schedule"],
  behaviors: PlanVersion["behaviors"],
  readings: string[],
): CatalogPlan {
  const version: PlanVersion = {
    id,
    version: 1,
    schedule,
    behaviors,
    readingDays: 7,
    assignments: readings.map((reading, index) => ({
      id: index + 1,
      reading: parseReading(reading, english),
    })),
    words: new Map(),
  };
  // Only what the reading module reads; a served plan has much more.
  return { id, version: 1, title, plan: version } as unknown as CatalogPlan;
}

const catalog: ServedCatalog = {
  importId: 1,
  registry,
  versification: english,
  bookSources: [],
  goals: [],
  plans: [
    plan(
      "mark-in-a-week",
      "Mark in a week",
      "sequence",
      ["pace", "finish-date"],
      ["MRK 1-2", "MRK 3-4", "MRK 5-6"],
    ),
    plan("ruth-in-a-week", "Ruth in a week", "sequence", ["pace"], ["RUT 1", "RUT 2", "RUT 3-4"]),
    plan(
      "proverbs-by-the-date",
      "Proverbs by the date",
      "day-of-month",
      ["calendar"],
      Array.from({ length: 31 }, (_, index) => `PRO ${index + 1}`),
    ),
  ],
};

const now = new Date("2027-03-01T12:00:00Z");

/** Adds the events an action makes to a journal, as the browser does. */
function act(events: unknown[], today: string, action: Record<string, unknown>): unknown[] {
  return [...events, ...newEvents({ events, today, zone: "Europe/London", action }, catalog, now)];
}

function cards(events: unknown[], today: string) {
  const request = journalRequest({ events, today }, catalog);
  return todayCards(catalog, request.journal, request.today);
}

const enroll = {
  kind: "enroll",
  plan: "mark-in-a-week",
  behavior: "pace",
  start: "2027-03-01",
  readingDays: [1, 2, 3, 4, 5],
};

describe("starting a plan", () => {
  it("makes one enrolled event, after the enrollment's own id", () => {
    const [event] = newEvents(
      { events: [], today: "2027-03-01", zone: "Europe/London", action: enroll },
      catalog,
      now,
    ) as [Record<string, string>];
    expect(event).toMatchObject({
      kind: "enrolled",
      plan: "mark-in-a-week",
      version: 1,
      behavior: "pace",
      start: "2027-03-01",
      readingDays: [1, 2, 3, 4, 5],
      zone: "Europe/London",
      device: "Web",
      at: "2027-03-01T12:00:00Z",
    });
    expect(eventIDMilliseconds(event["id"] as string)).toBeGreaterThan(
      eventIDMilliseconds(event["enrollment"] as string),
    );
  });

  it("refuses a plan, behavior or days the catalog does not permit", () => {
    const attempt = (action: Record<string, unknown>) => () =>
      newEvents({ events: [], today: "2027-03-01", action }, catalog, now);
    expect(attempt({ ...enroll, plan: "no-such-plan" })).toThrow(ReadingRequestError);
    expect(attempt({ ...enroll, behavior: "calendar" })).toThrow(ReadingRequestError);
    expect(attempt({ ...enroll, readingDays: [] })).toThrow(ReadingRequestError);
    expect(attempt({ ...enroll, readingDays: [3, 1] })).toThrow(ReadingRequestError);
    expect(attempt({ ...enroll, behavior: "finish-date" })).toThrow(ReadingRequestError);
    expect(attempt({ ...enroll, kind: "delete" })).toThrow(ReadingRequestError);
  });
});

describe("quiet celebrations", () => {
  const page = (events: unknown[], today: string) => {
    const request = journalRequest({ events, today }, catalog);
    return todayPage(catalog, request.journal, request.today);
  };
  const mark = (events: unknown[], today: string, assignment: number) =>
    act(events, today, {
      kind: "mark",
      mark: "completed",
      enrollment: cards(events, today)[0]?.enrollment,
      assignment,
    });

  it("says, in the plan's card, that the reader came back, finished a book and the plan", () => {
    const started = act([], "2027-03-01", { ...enroll, plan: "ruth-in-a-week" });
    const monday = mark(started, "2027-03-01", 1);
    // A first reading is a beginning, and Ruth is not read yet.
    expect(page(monday, "2027-03-01").cards[0]?.celebrations).toBeUndefined();
    const friday = mark(mark(monday, "2027-03-05", 2), "2027-03-05", 3);
    expect(page(friday, "2027-03-05")).toEqual({
      cards: [
        expect.objectContaining({
          status: "finished",
          celebrations: [
            "You've picked up where you left off.",
            "You've read all of Ruth.",
            "You've finished Ruth in a week.",
          ],
        }),
      ],
    });
    // A celebration is for its own day.
    expect(page(friday, "2027-03-08").cards[0]?.celebrations).toBeUndefined();
  });

  it("says once, after the cards, that the week's reading days were each read", () => {
    const started = act([], "2027-03-01", {
      ...enroll,
      plan: "ruth-in-a-week",
      readingDays: [1, 3],
    });
    const monday = mark(started, "2027-03-01", 1);
    expect(page(monday, "2027-03-01").rhythm).toBeUndefined();
    const wednesday = mark(monday, "2027-03-03", 2);
    expect(page(wednesday, "2027-03-03").rhythm).toBe(
      "You've read on each of your reading days this week.",
    );
  });
});

describe("Today, marking and undoing", () => {
  it("shows the next reading, then the day done with Undo, then the reading again", () => {
    const started = act([], "2027-03-01", enroll);
    const [first] = cards(started, "2027-03-01");
    expect(first).toMatchObject({ plan: "Mark in a week", status: "reading" });
    expect(first?.readings).toEqual([
      expect.objectContaining({
        label: "Mark in a week — Reading 1",
        assignment: 1,
        reference: expect.objectContaining({ display: "Mark 1–2" }),
      }),
    ]);

    const enrollment = first?.enrollment;
    const read = act(started, "2027-03-01", {
      kind: "mark",
      mark: "completed",
      enrollment,
      assignment: 1,
    });
    const [done] = cards(read, "2027-03-01");
    expect(done).toMatchObject({ status: "done", message: "That's today's reading." });
    expect(done?.readings).toEqual([]);
    expect(done?.lastMark?.message).toBe("Marked Mark 1–2 read.");

    const undone = act(read, "2027-03-01", {
      kind: "undo",
      enrollment,
      target: done?.lastMark?.event,
    });
    const [again] = cards(undone, "2027-03-01");
    expect(again?.status).toBe("reading");
    expect(again?.lastMark).toBeUndefined();
    // Tomorrow, yesterday's mark is history, not something to undo here.
    expect(cards(read, "2027-03-02")[0]?.lastMark).toBeUndefined();
  });

  it("refuses a change that would mean nothing", () => {
    const started = act([], "2027-03-01", enroll);
    const enrollment = cards(started, "2027-03-01")[0]?.enrollment;
    expect(() =>
      act(started, "2027-03-01", { kind: "undo", enrollment, target: "nothing" }),
    ).toThrow(ReadingRequestError);
    expect(() =>
      act(started, "2027-03-01", {
        kind: "mark",
        mark: "completed",
        enrollment: "someone-else",
        assignment: 1,
      }),
    ).toThrow(ReadingRequestError);
  });

  it("names a calendar day's reading by its date, and a short month's missing days", () => {
    const started = act([], "2027-11-30", {
      kind: "enroll",
      plan: "proverbs-by-the-date",
      behavior: "calendar",
      start: "2027-11-30",
      readingDays: [1, 2, 3, 4, 5, 6, 7],
    });
    const [card] = cards(started, "2027-11-30");
    expect(card?.readings[0]?.label).toBe("Proverbs by the date — Day 30");
    expect(card?.readings[0]?.appointed).toBe("2027-11-30");
    expect(card?.note).toBe(
      "This month has 30 days, so this plan has no reading for day 31 this month.",
    );
  });

  it("refuses a journal that is not a list, or a date that is not one", () => {
    expect(() => journalRequest({ events: "all", today: "2027-03-01" }, catalog)).toThrow(
      ReadingRequestError,
    );
    expect(() => journalRequest({ events: [], today: "today" }, catalog)).toThrow(
      ReadingRequestError,
    );
    expect(() => journalRequest([], catalog)).toThrow(ReadingRequestError);
  });

  it("shows the place in print, a YouVersion link, or where to choose a translation", () => {
    const started = act([], "2027-03-01", enroll);
    const request = journalRequest({ events: started, today: "2027-03-01" }, catalog);
    const reading = (options: Parameters<typeof todayCards>[3]) =>
      todayCards(catalog, request.journal, request.today, options)[0]?.readings[0];
    // A physical Bible is the default, as in the app.
    expect(reading({})?.print).toEqual(["Mark · chapters 1–2"]);
    expect(reading({ way: "youVersion", translation: 111 })?.open).toEqual({
      href: "https://www.bible.com/bible/111/MRK.1.NIV",
      note: "Opens at Mark 1, where this reading begins.",
    });
    expect(reading({ way: "youVersion" })?.chooseTranslation).toBe(true);
    expect(reading({ way: "youVersion", translation: 9999 })?.chooseTranslation).toBe(true);
    const other = reading({ way: "otherApp", convention: "kjv" });
    expect(other?.print).toBeUndefined();
    expect(other?.open).toBeUndefined();
  });

  it("welcomes the reader back after a gap, with each choice's effect, and records the answer", () => {
    const started = act([], "2027-03-01", enroll);
    const enrollment = cards(started, "2027-03-01")[0]?.enrollment;
    const read = act(started, "2027-03-01", {
      kind: "mark",
      mark: "completed",
      enrollment,
      assignment: 1,
    });
    // Tuesday to Thursday pass unread; on Friday the reader is welcomed back.
    const [back] = cards(read, "2027-03-05");
    expect(back?.welcome?.map((choice) => choice.choice)).toEqual(["continue"]);
    expect(back?.welcome?.[0]?.effect).toMatch(/^Your next reading will be Mark 3–4\. /);
    // Only a choice the engine offers today is recorded.
    expect(() => act(read, "2027-03-05", { kind: "return", enrollment, choice: "rejoin" })).toThrow(
      ReadingRequestError,
    );
    const answered = act(read, "2027-03-05", { kind: "return", enrollment, choice: "continue" });
    expect(cards(answered, "2027-03-05")[0]?.welcome).toBeUndefined();
  });

  it("offers a calendar plan's reader today's reading again, keeping the earlier ones", () => {
    const started = act([], "2027-11-01", {
      kind: "enroll",
      plan: "proverbs-by-the-date",
      behavior: "calendar",
      start: "2027-11-01",
      readingDays: [1, 2, 3, 4, 5, 6, 7],
    });
    const [back] = cards(started, "2027-11-10");
    expect(back?.welcome).toEqual([
      {
        choice: "rejoin",
        title: "Rejoin today's readings",
        effect: "Today's reading is Proverbs 10. Earlier readings stay in your history.",
      },
    ]);
  });

  it("logs an earlier day on that date, and offers Undo, then Redo, for the last action", () => {
    const started = act([], "2027-03-01", enroll);
    const enrollment = cards(started, "2027-03-01")[0]?.enrollment;
    const mark = { kind: "mark", mark: "completed", enrollment, assignment: 1 };
    expect(() => act(started, "2027-03-03", { ...mark, date: "2027-03-04" })).toThrow(
      ReadingRequestError,
    );
    expect(() => act(started, "2027-03-03", { ...mark, date: "2027-02-28" })).toThrow(
      ReadingRequestError,
    );
    const logged = act(started, "2027-03-03", { ...mark, date: "2027-03-01" });
    const lastAction = (logged.at(-1) as { id: string }).id;
    const request = journalRequest({ events: logged, today: "2027-03-03" }, catalog);
    const [card] = todayCards(catalog, request.journal, request.today, { lastAction });
    expect(card?.lastMark?.message).toBe("Marked Mark 1–2 read on Monday 1 March.");
    expect(card?.lastMark?.redo).toBeUndefined();
    // Without the tab's last action, a mark dated earlier is history, not Undo.
    expect(cards(logged, "2027-03-03")[0]?.lastMark).toBeUndefined();

    const undone = act(logged, "2027-03-03", { kind: "undo", enrollment, target: lastAction });
    const undo = (undone.at(-1) as { id: string }).id;
    const again = journalRequest({ events: undone, today: "2027-03-03" }, catalog);
    const [redo] = todayCards(catalog, again.journal, again.today, { lastAction: undo });
    expect(redo?.lastMark).toEqual({ event: undo, message: "Undone.", redo: true });
  });

  it("logs a calendar plan's earlier day as that date's own reading", () => {
    const started = act([], "2027-11-01", {
      kind: "enroll",
      plan: "proverbs-by-the-date",
      behavior: "calendar",
      start: "2027-11-01",
      readingDays: [1, 2, 3, 4, 5, 6, 7],
    });
    const enrollment = cards(started, "2027-11-03")[0]?.enrollment;
    const [logged] = newEvents(
      {
        events: started,
        today: "2027-11-03",
        action: { kind: "mark", mark: "completed", enrollment, assignment: 3, date: "2027-11-02" },
      },
      catalog,
      now,
    ) as [Record<string, unknown>];
    expect(logged).toMatchObject({ assignment: 2, date: "2027-11-02", appointed: "2027-11-02" });
  });

  it("keeps Progress: the week in words and symbols, and each plan's readings by state", () => {
    const started = act([], "2027-03-01", enroll);
    const enrollment = cards(started, "2027-03-01")[0]?.enrollment;
    const read = act(started, "2027-03-01", {
      kind: "mark",
      mark: "completed",
      enrollment,
      assignment: 1,
    });
    const request = journalRequest({ events: read, today: "2027-03-02" }, catalog);
    const progress = progressPage(catalog, request.journal, request.today);
    expect(progress.days.map((day) => day.symbol)).toEqual(["–", "–", "–", "–", "–", "✓", "○"]);
    expect(progress.days[5]?.label).toBe("Monday 1 March, read");
    expect(progress.days[6]?.label).toBe("Tuesday 2 March, not read");
    expect(progress.plans).toEqual([
      expect.objectContaining({
        plan: "Mark in a week",
        counts: "1 of 3 readings read",
        finished: false,
        next: "Next: Mark 3–4",
      }),
    ]);
    // The books read in, apart from any plan's record (P11.1), with what of
    // each was read (P11.4).
    expect(progress.books).toEqual([
      { name: "Mark", detail: "73 of 678 verses · 2 chapters read in full" },
    ]);
    expect(
      progressPage(
        catalog,
        journalRequest({ events: started, today: "2027-03-02" }, catalog).journal,
        request.today,
      ).books,
    ).toEqual([]);
  });

  it("counts each verse of a book once, and a chapter read in part as partial (P11.4)", () => {
    const started = act([], "2027-03-01", { ...enroll, plan: "ruth-in-a-week" });
    const enrollment = cards(started, "2027-03-01")[0]?.enrollment;
    const mark = (events: unknown[], assignment: number, kind = "completed", verses?: string) =>
      act(events, "2027-03-01", {
        kind: "mark",
        mark: kind,
        enrollment,
        assignment,
        ...(verses ? { verses } : {}),
      });
    const books = (events: unknown[]) => {
      const request = journalRequest({ events, today: "2027-03-01" }, catalog);
      return progressPage(catalog, request.journal, request.today).books;
    };
    // Ruth 1 read, and Ruth 2 marked part read with no verses said.
    const partly = mark(mark(started, 1), 2, "partlyCompleted");
    expect(books(partly)).toEqual([
      { name: "Ruth", detail: "22 of 85 verses · 1 chapter read in full · 1 chapter in part" },
    ]);
    // A second plan through Ruth adds nothing it already has.
    const again = act(partly, "2027-03-01", {
      ...enroll,
      plan: "ruth-in-a-week",
      start: "2027-03-01",
    });
    // The new plan, whichever order the same millisecond put them in.
    const second = journalRequest(
      { events: again, today: "2027-03-01" },
      catalog,
    ).journal.enrollments.find((candidate) => candidate.id !== enrollment)?.id;
    const repeated = act(again, "2027-03-01", {
      kind: "mark",
      mark: "completed",
      enrollment: second,
      assignment: 1,
    });
    expect(books(repeated)).toEqual(books(partly));
    // Every verse read: the book is whole.
    expect(books(mark(mark(partly, 2), 3))).toEqual([{ name: "Ruth", detail: "All 85 verses" }]);
  });

  it("says the reading days in a row only when the reader asks, and never zero (D17)", () => {
    const started = act([], "2027-03-01", enroll);
    const enrollment = cards(started, "2027-03-01")[0]?.enrollment;
    const mark = (events: unknown[], today: string, assignment: number) =>
      act(events, today, { kind: "mark", mark: "completed", enrollment, assignment });
    const twoDays = mark(mark(started, "2027-03-01", 1), "2027-03-02", 2);
    const on = (events: unknown[], today: string) => {
      const request = journalRequest({ events, today }, catalog);
      return progressPage(catalog, request.journal, request.today, { streak: true }).inARow;
    };
    const request = journalRequest({ events: twoDays, today: "2027-03-02" }, catalog);
    // Off unless turned on.
    expect(progressPage(catalog, request.journal, request.today).inARow).toBeUndefined();
    expect(on(twoDays, "2027-03-02")).toBe("2 reading days in a row");
    // Wednesday morning, not yet read, still counts Monday and Tuesday.
    expect(on(twoDays, "2027-03-03")).toBe("2 reading days in a row");
    expect(on(mark(started, "2027-03-01", 1), "2027-03-01")).toBe("1 reading day in a row");
    // Nothing is said when there is none: never a zero.
    expect(on(started, "2027-03-01")).toBeUndefined();
    expect(on(twoDays, "2027-03-05")).toBeUndefined();
  });

  it("keeps each plan's history: every reading's state and every change, newest first (P11.5)", () => {
    const started = act([], "2027-03-01", enroll);
    const enrollment = cards(started, "2027-03-01")[0]?.enrollment;
    const read = act(started, "2027-03-01", {
      kind: "mark",
      mark: "completed",
      enrollment,
      assignment: 1,
    });
    const skipped = act(read, "2027-03-02", {
      kind: "mark",
      mark: "skipped",
      enrollment,
      assignment: 2,
    });
    const page = (events: unknown[], today: string) => {
      const request = journalRequest({ events, today }, catalog);
      return progressPage(catalog, request.journal, request.today).plans[0];
    };
    const plan = page(skipped, "2027-03-02");
    expect(plan?.group).toBe("reading");
    expect(plan?.readings).toEqual([
      expect.objectContaining({
        label: "Reading 1",
        reference: "Mark 1–2",
        state: "Read on Monday 1 March",
        markable: false,
      }),
      expect.objectContaining({
        label: "Reading 2",
        reference: "Mark 3–4",
        state: "Skipped on Tuesday 2 March",
        markable: true,
      }),
      expect.objectContaining({
        label: "Reading 3",
        reference: "Mark 5–6",
        state: "Not yet read",
        markable: false,
      }),
    ]);
    expect(plan?.readings[0]?.undo).toBeDefined();
    expect(plan?.changes).toEqual([
      "Skipped Mark 3–4 on Tuesday 2 March.",
      "Marked Mark 1–2 read on Monday 1 March.",
      "Started the plan from Monday 1 March.",
    ]);

    // From History: the skipped reading marked read on an earlier date, and
    // the first reading's mark taken back.
    const later = act(skipped, "2027-03-03", {
      kind: "mark",
      mark: "completed",
      enrollment,
      assignment: 2,
      date: "2027-03-02",
    });
    const undone = act(later, "2027-03-03", {
      kind: "undo",
      enrollment,
      target: plan?.readings[0]?.undo,
    });
    const after = page(undone, "2027-03-03");
    expect(after?.readings.map((reading) => reading.state)).toEqual([
      "Not yet read",
      "Read on Tuesday 2 March",
      "Not yet read",
    ]);
    expect(after?.changes.slice(0, 2)).toEqual([
      "Took back: Marked Mark 1–2 read on Monday 1 March.",
      "Marked Mark 3–4 read on Tuesday 2 March.",
    ]);
  });

  it("groups plans: reading, finished and stopped, and lists a calendar plan's days (P11.5)", () => {
    const started = act([], "2027-03-01", enroll);
    const enrollment = cards(started, "2027-03-01")[0]?.enrollment;
    let finished = started;
    for (const assignment of [1, 2, 3]) {
      finished = act(finished, "2027-03-01", {
        kind: "mark",
        mark: "completed",
        enrollment,
        assignment,
      });
    }
    const proverbs = act(finished, "2027-03-01", {
      kind: "enroll",
      plan: "proverbs-by-the-date",
      behavior: "calendar",
      start: "2027-03-01",
      readingDays: [1, 2, 3, 4, 5, 6, 7],
    });
    const request = journalRequest({ events: proverbs, today: "2027-03-03" }, catalog);
    // Both were started in the test's same millisecond, so find each by name.
    const plans = progressPage(catalog, request.journal, request.today).plans;
    const byName = (name: string) => plans.find((plan) => plan.plan === name);
    expect(byName("Mark in a week")?.group).toBe("finished");
    expect(byName("Proverbs by the date")?.group).toBe("reading");
    // A calendar plan's history is its appointed days to today, each one markable.
    expect(byName("Proverbs by the date")?.readings).toEqual([
      expect.objectContaining({
        label: "Monday 1 March",
        reference: "Proverbs 1",
        appointed: "2027-03-01",
        markable: true,
      }),
      expect.objectContaining({
        label: "Tuesday 2 March",
        reference: "Proverbs 2",
        markable: true,
      }),
      expect.objectContaining({
        label: "Wednesday 3 March",
        reference: "Proverbs 3",
        markable: true,
      }),
    ]);
    // Marked from History on Wednesday, Monday's reading keeps its own slot.
    const second = byName("Proverbs by the date")?.enrollment;
    const [made] = newEvents(
      {
        events: proverbs,
        today: "2027-03-03",
        zone: "Europe/London",
        action: {
          kind: "mark",
          mark: "completed",
          enrollment: second,
          assignment: 1,
          appointed: "2027-03-01",
          date: "2027-03-03",
        },
      },
      catalog,
      now,
    ) as [Record<string, unknown>];
    expect(made).toMatchObject({ assignment: 1, appointed: "2027-03-01", date: "2027-03-03" });
    const stopped = act(proverbs, "2027-03-03", { kind: "end", enrollment: second });
    const again = journalRequest({ events: stopped, today: "2027-03-03" }, catalog);
    expect(
      progressPage(catalog, again.journal, again.today).plans.find(
        (plan) => plan.enrollment === second,
      )?.group,
    ).toBe("stopped");
  });

  it("pauses, resumes, stops following and follows a plan again, keeping its record (P11.5)", () => {
    const started = act([], "2027-03-01", enroll);
    const enrollment = cards(started, "2027-03-01")[0]?.enrollment;
    const plan = (events: unknown[], today: string) => {
      const request = journalRequest({ events, today }, catalog);
      return progressPage(catalog, request.journal, request.today).plans[0];
    };
    expect(plan(started, "2027-03-01")?.actions).toEqual({
      pause: true,
      end: true,
      calendar: true,
    });
    const paused = act(started, "2027-03-02", { kind: "pause", enrollment });
    expect(plan(paused, "2027-03-02")).toMatchObject({
      group: "paused",
      actions: { resume: true, end: true },
    });
    expect(cards(paused, "2027-03-02")[0]?.status).toBe("paused");
    // Pausing twice means nothing, and is refused.
    expect(() => act(paused, "2027-03-02", { kind: "pause", enrollment })).toThrow(
      ReadingRequestError,
    );
    const resumed = act(paused, "2027-03-04", { kind: "resume", enrollment });
    expect(plan(resumed, "2027-03-04")?.group).toBe("reading");
    expect(plan(resumed, "2027-03-04")?.changes.slice(0, 2)).toEqual([
      "Resumed on Thursday 4 March.",
      "Paused from Tuesday 2 March.",
    ]);
    const ended = act(resumed, "2027-03-04", { kind: "end", enrollment });
    const stopped = plan(ended, "2027-03-04");
    expect(stopped?.group).toBe("stopped");
    expect(cards(ended, "2027-03-04")).toEqual([]);
    const again = act(ended, "2027-03-04", {
      kind: "undo",
      enrollment,
      target: stopped?.actions.restore,
    });
    expect(plan(again, "2027-03-04")?.group).toBe("reading");
  });

  it("previews a finish date's load, and refuses one beyond the reader's limit", () => {
    const finishing = {
      ...enroll,
      behavior: "finish-date",
      finish: "2027-03-03",
      readingDays: [1, 2, 3, 4, 5, 6, 7],
      limit: 1,
    };
    // Three readings over Monday to Wednesday: one a day fits a limit of one.
    expect(
      startPreview({ events: [], today: "2027-03-01", action: finishing }, catalog, now),
    ).toEqual({ text: "1 reading a day, on 3 reading days.", fits: true });
    // By Tuesday it would take two a day; at one a day it ends on Wednesday.
    const tooSoon = { ...finishing, finish: "2027-03-02" };
    expect(
      startPreview({ events: [], today: "2027-03-01", action: tooSoon }, catalog, now),
    ).toEqual({
      text: "To finish by Tuesday 2 March you'd read up to 2 readings a day. At 1 a day you'd finish on Wednesday 3 March.",
      fits: false,
      later: "2027-03-03",
    });
    expect(() => act([], "2027-03-01", tooSoon)).toThrow(ReadingRequestError);
    expect(startPreview({ events: [], today: "2027-03-01", action: enroll }, catalog, now)).toBe(
      undefined,
    );
  });

  it("keeps the id a mark made offline came with, and makes nothing of it twice", () => {
    const started = act([], "2027-03-01", enroll);
    const enrollment = cards(started, "2027-03-01")[0]?.enrollment;
    const id = makeEventID(now.getTime() + 60_000, Array<number>(10).fill(1)) as string;
    const mark = { kind: "mark", mark: "completed", enrollment, assignment: 1, id };
    const marked = act(started, "2027-03-01", mark);
    expect((marked.at(-1) as { id: string }).id).toBe(id);
    expect(act(marked, "2027-03-01", mark)).toHaveLength(marked.length);
    expect(() => act(started, "2027-03-01", { ...mark, id: "not-an-id" })).toThrow(
      ReadingRequestError,
    );
  });
});

describe("a calendar of the readings ahead (P13.4)", () => {
  const options = { stamp: "2027-03-02T08:00:00Z" };

  it("makes an all-day event for each day with readings, from the engine's days ahead", () => {
    const started = act([], "2027-03-01", enroll);
    const enrollment = cards(started, "2027-03-01")[0]?.enrollment as string;
    const read = act(started, "2027-03-01", {
      kind: "mark",
      mark: "completed",
      enrollment,
      assignment: 1,
    });
    const request = journalRequest({ events: read, today: "2027-03-02" }, catalog);
    const { plan, file } = calendarFor(
      catalog,
      request.journal,
      request.today,
      enrollment,
      options,
    );
    expect(plan).toBe("Mark in a week");
    const lines = file.split("\r\n");
    // Readings 2 and 3 on Tuesday and Wednesday; reading 1 is read.
    expect(lines.filter((line) => line === "BEGIN:VEVENT")).toHaveLength(2);
    expect(lines).toContain("DTSTART;VALUE=DATE:20270302");
    expect(lines).toContain("DTSTART;VALUE=DATE:20270303");
    expect(lines).toContain("SUMMARY:Mark in a week: Mark 3–4");
    expect(lines).toContain("SUMMARY:Mark in a week: Mark 5–6");
    expect(lines).toContain("DTSTAMP:20270302T080000Z");
    expect(file).not.toContain("Mark 1–2");
  });

  it("gives a calendar plan its own dates, labelled by the day", () => {
    const started = act([], "2027-03-30", {
      kind: "enroll",
      plan: "proverbs-by-the-date",
      behavior: "calendar",
      start: "2027-03-30",
      readingDays: [1, 2, 3, 4, 5, 6, 7],
    });
    const enrollment = cards(started, "2027-03-30")[0]?.enrollment as string;
    const request = journalRequest({ events: started, today: "2027-03-30" }, catalog);
    const { file } = calendarFor(catalog, request.journal, request.today, enrollment, options);
    expect(file.match(/BEGIN:VEVENT/g)).toHaveLength(28);
    expect(file).toContain(
      "DTSTART;VALUE=DATE:20270401\r\nDTEND;VALUE=DATE:20270402\r\nSUMMARY:Proverbs by the date: Proverbs 1",
    );
    expect(file).toContain(
      "DESCRIPTION:Day 1. Read it in your own Bible\\, then mark it read in Day by",
    );
  });

  it("refuses a plan that is not being followed", () => {
    const request = journalRequest({ events: [], today: "2027-03-01" }, catalog);
    expect(() => calendarFor(catalog, request.journal, request.today, "no-such", options)).toThrow(
      ReadingRequestError,
    );
  });
});
