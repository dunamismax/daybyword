// The journal beyond its shared cases (tests/fixtures/journal.json): the
// properties the cases cannot state one input at a time, as Swift's
// JournalTests check them.
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  eventIDMilliseconds,
  isEventID,
  Journal,
  journalEventWire,
  JournalError,
  makeEventID,
  parseJournalEvent,
  parseReading,
  parseWallTime,
  Versification,
  wallTimeText,
  assignmentPositions,
  type JournalEvent,
  type PlanVersion,
} from "#lib/domain/index.ts";
import { canonicalJSON, type FixtureFile } from "./parity.ts";

const repository = new URL("../../../", import.meta.url);
const read = (path: string) => readFileSync(new URL(path, repository), "utf8");

const english = new Versification("english", read("catalog/scripture/versification/english.tsv"));
const file = JSON.parse(read("tests/fixtures/journal.json")) as FixtureFile;
const plans: PlanVersion[] = (file.plans ?? []).map((plan) => ({
  ...plan,
  assignments: plan.assignments.map(({ id, reading }) => ({
    id,
    reading: parseReading(reading, english),
  })),
}));

/** The cases whose journals fold, with their events read. */
const folding = file.cases.flatMap((testCase) => {
  try {
    const { events } = testCase.input as { events: unknown[] };
    const parsed = events.map((event, index) => parseJournalEvent(event, index + 1));
    new Journal(parsed, plans);
    return [{ name: testCase.name ?? "", events: parsed }];
  } catch (error) {
    if (error instanceof JournalError) return [];
    throw error;
  }
});

/** What a fold comes to, for comparing two folds. */
function summary(events: readonly JournalEvent[]): string {
  const journal = new Journal(events, plans);
  return canonicalJSON({
    events: journal.events.map(journalEventWire),
    inert: journal.inert,
    active: journal.events.map((event) => journal.isActive(event.id)),
    enrollments: journal.enrollments.map((enrollment) => ({
      settled: enrollment.settled,
      pauses: enrollment.pauses,
      start: enrollment.start,
      ended: enrollment.ended ?? null,
    })),
  });
}

/** A shuffle from a fixed seed, so it is the same every run. */
function shuffler(seed: number) {
  let state = seed;
  return <T>(items: readonly T[]): T[] => {
    const out = [...items];
    for (let index = out.length - 1; index > 0; index -= 1) {
      state = (state * 1_103_515_245 + 12_345) % 2_147_483_648;
      const other = state % (index + 1);
      [out[index], out[other]] = [out[other] as T, out[index] as T];
    }
    return out;
  };
}

describe("the journal's fold", () => {
  it("is the same in any arrival order, and when every event is sent twice", () => {
    expect(folding.length).toBeGreaterThanOrEqual(30);
    const shuffle = shuffler(2027);
    for (const { name, events } of folding) {
      const expected = summary(events);
      expect(summary([...events].reverse()), name).toBe(expected);
      for (let round = 0; round < 5; round += 1) {
        expect(summary(shuffle(events)), name).toBe(expected);
      }
      expect(summary([...events, ...events]), name).toBe(expected);
    }
  });

  it("reads every event back from its wire form", () => {
    const kinds = new Set<string>();
    for (const { events } of folding) {
      for (const event of events) {
        kinds.add(event.kind);
        const wire = JSON.parse(JSON.stringify(journalEventWire(event))) as unknown;
        expect(parseJournalEvent(wire, 1)).toEqual(event);
      }
    }
    expect(kinds.size).toBe(10);
  });
});

describe("event ids", () => {
  it("sort, as text, by the time they were made", () => {
    const earlier = makeEventID(1_803_898_923_456, Array<number>(10).fill(255));
    const later = makeEventID(1_803_898_923_457, Array<number>(10).fill(0));
    if (!earlier || !later) throw new Error("no ids");
    expect(earlier < later).toBe(true);
    expect(isEventID(earlier)).toBe(true);
    expect(eventIDMilliseconds(earlier)).toBe(1_803_898_923_456);
    expect(makeEventID(2 ** 48, Array<number>(10).fill(0))).toBeUndefined();
    expect(makeEventID(0, [])).toBeUndefined();
    expect(makeEventID(0, Array<number>(10).fill(0.5))).toBeUndefined();
  });
});

describe("wall-clock times", () => {
  it("are written and read back", () => {
    const written = ["07:05", "00:00", "23:59"].map((text) => {
      const time = parseWallTime(text);
      return time && wallTimeText(time);
    });
    expect(written).toEqual(["07:05", "00:00", "23:59"]);
    expect(
      ["24:00", "07:60", "7:05", "07:5", "0705", "07:05:00", " 07:05", "０７:05", ""].map(
        parseWallTime,
      ),
    ).toEqual(Array(9).fill(undefined));
  });
});

describe("a plan version", () => {
  it("gives each assignment its place in reading order", () => {
    const second = plans.find((plan) => plan.version === 2);
    if (!second) throw new Error("no version 2");
    const positions = assignmentPositions(second);
    expect([positions.get(11), positions.get(4), positions.get(12)]).toEqual([4, 5, undefined]);
  });
});
