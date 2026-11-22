// The served catalog as the web's own role reads it, and what the plan
// pages make of it, against a real PostgreSQL holding the repository's
// release export (make test-db).
import { execFile } from "node:child_process";
import { readFileSync } from "node:fs";
import { promisify } from "node:util";
import pg from "pg";
import { afterAll, describe, expect, it } from "vitest";
import {
  dayText,
  planGroups,
  planList,
  planPage,
  planSuggestions,
  planWeek,
} from "#lib/server/catalog/present.ts";
import { closeCatalog, servedCatalog } from "#lib/server/catalog/read.ts";

const run = promisify(execFile);
const web = new URL("../../", import.meta.url).pathname;
const fixture = new URL("../../../tests/fixtures/catalog-export.json", import.meta.url).pathname;
const repositoryExport = process.env["DBW_REPOSITORY_EXPORT"];
if (!process.env["PGHOST"] || !repositoryExport)
  throw new Error("run these through make test-db (scripts/with-postgres.sh)");

const name = `dbw_read_${process.pid}`;
const url = `postgresql://daybyword_web@localhost/${name}?host=${process.env["PGHOST"]}`;

async function job(script: string, args: string[]) {
  return run("node", [`scripts/${script}`, ...args], {
    cwd: web,
    env: {
      ...process.env,
      PGDATABASE: name,
      PGUSER: "daybyword_migration",
      DB_OWNER_ROLE: "daybyword_owner",
    },
  });
}

afterAll(closeCatalog);

describe("the served catalog", () => {
  it("is none without a database, and none before an import", async () => {
    expect(await servedCatalog("")).toBeUndefined();
    const admin = new pg.Client({ database: "postgres" });
    await admin.connect();
    await admin.query(`create database ${name}`);
    await admin.end();
    const owner = new pg.Client({ database: name });
    await owner.connect();
    await owner.query(readFileSync(new URL("../../db/roles.sql", import.meta.url), "utf8"));
    await owner.end();
    await job("db-migrate.ts", []);
    expect(await servedCatalog(url)).toBeUndefined();
  }, 120_000);

  it("holds the release's plans with their facts, readings and scripture", async () => {
    await job("catalog-import.ts", [repositoryExport]);
    const catalog = await servedCatalog(url);
    const exported = JSON.parse(readFileSync(repositoryExport, "utf8")) as {
      plans: { id: string; title: string; assignments: unknown[]; facts: { verses: number } }[];
    };
    expect(catalog?.plans.map((plan) => plan.id)).toEqual(exported.plans.map((plan) => plan.id));
    for (const plan of catalog?.plans ?? []) {
      const source = exported.plans.find((other) => other.id === plan.id);
      expect(plan.title).toBe(source?.title);
      expect(plan.plan.assignments.length).toBe(source?.assignments.length);
      expect(plan.plan.words?.size).toBe(source?.assignments.length);
      expect(plan.facts.verses).toBe(source?.facts.verses);
      expect(plan.books.length).toBeGreaterThan(0);
    }
    // The same import is read once and kept.
    expect(await servedCatalog(url)).toBe(catalog);
  }, 120_000);

  it("gives the plan pages their list, sample weeks and coverage", async () => {
    const catalog = await servedCatalog(url);
    if (!catalog) throw new Error("no catalog");
    expect(planList(catalog).map((plan) => plan.id)).toEqual([
      "proverbs-through-the-month",
      "gospels-at-your-pace",
      "pauls-letters",
      "psalm-a-day",
      "bible-in-a-year-five-days",
      "new-testament-in-a-year-five-days",
      "bible-in-a-year",
    ]);
    const page = (id: string) => {
      const entry = catalog.plans.find((plan) => plan.id === id);
      if (!entry) throw new Error(`no ${id}`);
      return planPage(catalog, entry);
    };

    const gospels = page("gospels-at-your-pace");
    expect(gospels.readings).toBe("60 readings");
    expect(gospels.length).toBe("60 readings: about 12 weeks at 5 readings a week.");
    expect(gospels.permissions).toBe(
      "Day by Word's own plan: free to follow, to print for your own use, and to share by its link.",
    );
    expect(page("proverbs-through-the-month").length).toBe(
      "A reading for each day of the month, begun again each month.",
    );
    expect(gospels.sample.map((day) => day.label)).toEqual([
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ]);
    expect(gospels.sample[0]?.reference).toEqual({
      display: "Matthew 1–3",
      spoken: "Matthew, chapters 1 to 3",
    });
    // A five-day plan's weekend is rest, said as rest.
    expect(gospels.sample.slice(5).every((day) => day.reference === undefined)).toBe(true);
    expect(gospels.covers[0]).toBe("Every verse of Matthew, Mark, Luke, and John: 3,779 verses.");
    expect(gospels.behaviors.map((behavior) => behavior.name)).toEqual([
      "Continue at my pace",
      "Work toward a finish date",
    ]);
    expect(gospels.workloads.map((workload) => workload.text)).toEqual([
      "About 6–8 minutes",
      "About 3–4 minutes",
      "About 8–10 minutes",
    ]);

    const proverbs = page("proverbs-through-the-month");
    expect(proverbs.sample.map((day) => day.label)).toEqual(
      [1, 2, 3, 4, 5, 6, 7].map((day) => `Day ${day}`),
    );
    expect(proverbs.sample[6]?.reference?.display).toBe("Proverbs 7");
    expect(proverbs.behaviors.map((behavior) => behavior.name)).toEqual(["Follow the calendar"]);

    const year = page("bible-in-a-year");
    expect(year.covers).toEqual([
      "Every verse of the 66 books of the Protestant canon: 31,102 verses.",
      "No verse is read twice.",
    ]);
    expect(year.sample.every((day) => day.reference !== undefined)).toBe(true);
  });

  it("gives a week's checklist from a start date, or the sample week without one", async () => {
    const catalog = await servedCatalog(url);
    if (!catalog) throw new Error("no catalog");
    const entry = (id: string) => {
      const found = catalog.plans.find((plan) => plan.id === id);
      if (!found) throw new Error(`no ${id}`);
      return found;
    };
    expect(dayText({ year: 2027, month: 1, day: 6 })).toBe("Wednesday 6 January");

    const sample = planWeek(catalog, entry("gospels-at-your-pace"));
    expect(sample.start).toBeUndefined();
    expect(sample.days.map((day) => ({ label: day.label, reference: day.references[0] }))).toEqual(
      planPage(catalog, entry("gospels-at-your-pace")).sample.map((day) => ({
        label: day.label,
        reference: day.reference,
      })),
    );

    // Begun on a Wednesday, a five-day plan reads Wednesday to Friday and
    // Monday and Tuesday, and rests at the weekend.
    const gospels = planWeek(catalog, entry("gospels-at-your-pace"), "2027-01-06");
    expect(gospels.start).toBe("2027-01-06");
    expect(gospels.days.map((day) => day.label)).toEqual([
      "Wednesday 6 January",
      "Thursday 7 January",
      "Friday 8 January",
      "Saturday 9 January",
      "Sunday 10 January",
      "Monday 11 January",
      "Tuesday 12 January",
    ]);
    expect(gospels.days.map((day) => day.references.map((found) => found.display))).toEqual([
      ["Matthew 1–3"],
      ["Matthew 4–5"],
      ["Matthew 6–7"],
      [],
      [],
      ["Matthew 8–9"],
      ["Matthew 10–11"],
    ]);
    expect(gospels.note).toContain("begun on Wednesday 6 January");

    // A calendar plan's week is the dates' own readings across a month's
    // end; a short month does not appoint the days it lacks (docs/engine.md).
    const proverbs = planWeek(catalog, entry("proverbs-through-the-month"), "2027-02-26");
    expect(proverbs.days.map((day) => day.references.map((found) => found.display))).toEqual([
      ["Proverbs 26"],
      ["Proverbs 27"],
      ["Proverbs 28"],
      ["Proverbs 1"],
      ["Proverbs 2"],
      ["Proverbs 3"],
      ["Proverbs 4"],
    ]);
  });

  it("groups the plans by goal and suggests plans in the app's words", async () => {
    const catalog = await servedCatalog(url);
    if (!catalog) throw new Error("no catalog");
    expect(planGroups(catalog).map((group) => group.label)).toEqual([
      "A place to begin",
      "The whole Bible",
      "The New Testament",
      "The Gospels",
      "The Psalms and Proverbs",
    ]);
    expect(planGroups(catalog)[0]?.plans.map((plan) => plan.id)).toEqual(["gospels-at-your-pace"]);
    // docs/engine.md's example, as apple/AppTests/LibraryTests.swift has it.
    const suggested = planSuggestions(catalog, { hope: "whole-bible", time: "medium", days: 5 });
    expect(suggested.map((plan) => plan.id)).toEqual([
      "bible-in-a-year-five-days",
      "bible-in-a-year",
    ]);
    expect(suggested[0]?.reasons).toEqual([
      "A plan for reading the whole Bible.",
      "A typical reading takes about 12 to 16 minutes, longer than you said.",
      "It's paced for 5 reading days a week, as you said.",
      "At 5 readings a week it takes about 52 weeks.",
    ]);
    expect(suggested[1]?.reasons).toEqual([
      "A plan for reading the whole Bible.",
      "You said about 10 minutes. A typical reading takes about 9 to 11 minutes.",
      "It's paced for every day, more than you said.",
      "At 5 readings a week it takes about 73 weeks.",
    ]);
    const calendar = planSuggestions(catalog, { time: "short", days: 7 });
    expect(calendar[0]?.id).toBe("proverbs-through-the-month");
    expect(calendar[0]?.reasons.at(-1)).toBe("It has a reading for each date of the month.");
  });

  it("follows a new import", async () => {
    const before = await servedCatalog(url);
    await job("catalog-import.ts", [fixture]);
    const after = await servedCatalog(url);
    expect(after?.importId).not.toBe(before?.importId);
    expect(after?.plans.length).toBe(2);
  }, 120_000);
});
