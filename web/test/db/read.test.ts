// The served catalog as the web's own role reads it, and what the plan
// pages make of it, against a real PostgreSQL holding the repository's
// release export (make test-db).
import { execFile } from "node:child_process";
import { readFileSync } from "node:fs";
import { promisify } from "node:util";
import pg from "pg";
import { afterAll, describe, expect, it } from "vitest";
import { planList, planPage } from "#lib/server/catalog/present.ts";
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
      "bible-in-a-year",
    ]);
    const page = (id: string) => {
      const entry = catalog.plans.find((plan) => plan.id === id);
      if (!entry) throw new Error(`no ${id}`);
      return planPage(catalog, entry);
    };

    const gospels = page("gospels-at-your-pace");
    expect(gospels.readings).toBe("60 readings");
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

  it("follows a new import", async () => {
    const before = await servedCatalog(url);
    await job("catalog-import.ts", [fixture]);
    const after = await servedCatalog(url);
    expect(after?.importId).not.toBe(before?.importId);
    expect(after?.plans.length).toBe(2);
  }, 120_000);
});
