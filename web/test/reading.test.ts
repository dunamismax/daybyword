// The web's own record, worked out on the server from what the browser
// sends (BUILD.md P8.10c, docs/decisions.md E52): starting a plan, Today's
// cards, marking and undoing, and the requests that are refused. The plans
// are invented (tests/fixtures/README.md); the scripture is the catalog's.
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  BookRegistry,
  eventIDMilliseconds,
  parseReading,
  Versification,
  type PlanVersion,
} from "#lib/domain/index.ts";
import type { CatalogPlan, ServedCatalog } from "#lib/server/catalog/read.ts";
import { journalRequest, newEvents, ReadingRequestError, todayCards } from "#lib/server/reading.ts";

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
  plans: [
    plan(
      "mark-in-a-week",
      "Mark in a week",
      "sequence",
      ["pace", "finish-date"],
      ["MRK 1-2", "MRK 3-4", "MRK 5-6"],
    ),
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
});
