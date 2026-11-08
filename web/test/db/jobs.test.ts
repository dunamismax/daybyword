// The one-shot jobs as a deploy runs them: node on the scripts, as
// daybyword_migrate, against a new database (make test-db).
import { execFile } from "node:child_process";
import { readFileSync } from "node:fs";
import { promisify } from "node:util";
import pg from "pg";
import { describe, expect, it } from "vitest";

const run = promisify(execFile);
const web = new URL("../../", import.meta.url).pathname;
const fixture = new URL("../../../tests/fixtures/catalog-export.json", import.meta.url).pathname;
const repositoryExport = process.env["DBW_REPOSITORY_EXPORT"];

async function job(script: string, args: string[], database: string) {
  return run("node", [`scripts/${script}`, ...args], {
    cwd: web,
    env: { ...process.env, PGDATABASE: database, PGUSER: "daybyword_migrate" },
  });
}

describe("the migration and import jobs", () => {
  it("migrate, import the repository's release export and the fixture, and report", async () => {
    const name = `dbw_jobs_${process.pid}`;
    const admin = new pg.Client({ database: "postgres" });
    await admin.connect();
    await admin.query(`create database ${name}`);
    await admin.end();
    const owner = new pg.Client({ database: name });
    await owner.connect();
    await owner.query(readFileSync(new URL("../../db/roles.sql", import.meta.url), "utf8"));
    await owner.end();

    await expect(job("catalog-import.ts", [fixture], name)).rejects.toThrow(/run make db-migrate/);
    expect((await job("db-migrate.ts", [], name)).stdout).toMatch(/the schema is current/);
    expect((await job("db-migrate.ts", [], name)).stdout).toMatch(/the schema is current/);

    if (!repositoryExport)
      throw new Error("DBW_REPOSITORY_EXPORT names make catalog-export's output");
    expect((await job("catalog-import.ts", [repositoryExport], name)).stdout).toMatch(/imported/);
    expect((await job("catalog-import.ts", [fixture], name)).stdout).toMatch(/: imported/);
    expect((await job("catalog-import.ts", [fixture], name)).stdout).toMatch(/already-current/);
    expect((await job("catalog-import.ts", ["--check", fixture], name)).stdout).toMatch(
      /valid release export of 2 plan/,
    );
    await expect(job("catalog-import.ts", ["--force", fixture], name)).rejects.toThrow(/usage/);
  });
});
