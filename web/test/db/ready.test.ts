// /up's readiness against a real database (make test-db): not ready until
// the migrations ran and a catalog is current, as the read-only web role.
import { execFile } from "node:child_process";
import { readFileSync } from "node:fs";
import { promisify } from "node:util";
import pg from "pg";
import { afterAll, describe, expect, it } from "vitest";
import { closeReadiness, databaseReady } from "#lib/server/db/ready.ts";

const run = promisify(execFile);
const web = new URL("../../", import.meta.url).pathname;
const fixture = new URL("../../../tests/fixtures/catalog-export.json", import.meta.url).pathname;

afterAll(closeReadiness);

describe("readiness", () => {
  it("waits for the migrations and a current catalog", async () => {
    const name = `dbw_ready_${process.pid}`;
    const admin = new pg.Client({ database: "postgres" });
    await admin.connect();
    await admin.query(`create database ${name}`);
    await admin.end();
    const owner = new pg.Client({ database: name });
    await owner.connect();
    await owner.query(readFileSync(new URL("../../db/roles.sql", import.meta.url), "utf8"));
    await owner.end();

    const host = encodeURIComponent(process.env["PGHOST"] ?? "");
    const url = `postgresql://daybyword_web@/${name}?host=${host}&port=${process.env["PGPORT"] ?? "5432"}`;
    expect(await databaseReady(url)).toBe(false);

    const env = {
      ...process.env,
      PGDATABASE: name,
      PGUSER: "daybyword_migration",
      DB_OWNER_ROLE: "daybyword_owner",
    };
    await run("node", ["scripts/db-migrate.ts"], { cwd: web, env });
    await closeReadiness();
    expect(await databaseReady(url)).toBe(false);

    await run("node", ["scripts/catalog-import.ts", fixture], { cwd: web, env });
    await closeReadiness();
    expect(await databaseReady(url)).toBe(true);
  });

  it("is ready with no database configured, and not with one that does not answer", async () => {
    expect(await databaseReady("")).toBe(true);
    await closeReadiness();
    expect(await databaseReady("postgresql://nobody@127.0.0.1:1/none")).toBe(false);
    await closeReadiness();
  });
});
