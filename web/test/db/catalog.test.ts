// Against a real PostgreSQL (make test-db, scripts/with-postgres.sh). Each test
// gets its own new database with the project's roles (db/roles.sql).
import { readFileSync } from "node:fs";
import pg from "pg";
import { afterAll, describe, expect, it } from "vitest";
import { ExportError } from "../../src/catalog/export.ts";
import { importCatalog } from "../../src/catalog/import.ts";
import { database } from "../../src/db/client.ts";
import {
  applyMigrations,
  checkSchema,
  knownMigrations,
  SchemaError,
} from "../../src/db/migrations.ts";
import { assignment, changedExport, fixtureExport, plan } from "../helpers.ts";

if (!process.env["PGHOST"])
  throw new Error("run these through make test-db (scripts/with-postgres.sh)");

const roles = readFileSync(new URL("../../db/roles.sql", import.meta.url), "utf8");
const pools: pg.Pool[] = [];
let counter = 0;

async function freshDatabase() {
  const name = `dbw_test_${process.pid}_${++counter}`;
  const admin = new pg.Client({ database: "postgres" });
  await admin.connect();
  await admin.query(`create database ${name}`);
  await admin.end();
  const owner = new pg.Client({ database: name });
  await owner.connect();
  await owner.query(roles);
  await owner.end();
  const connect = (user: string) => {
    const pool = new pg.Pool({ database: name, user });
    pools.push(pool);
    return pool;
  };
  const migratePool = connect("daybyword_migrate");
  return { name, migratePool, migrator: database(migratePool), app: connect("daybyword_app") };
}

async function count(pool: pg.Pool, table: string): Promise<number> {
  const result = await pool.query<{ n: string }>(`select count(*) as n from ${table}`);
  return Number(result.rows[0]?.n);
}

async function served(pool: pg.Pool): Promise<number | undefined> {
  const result = await pool.query<{ import_id: number }>("select import_id from catalog_current");
  return result.rows[0]?.import_id;
}

afterAll(async () => {
  await Promise.all(pools.map((p) => p.end()));
});

describe("migrations", () => {
  it("create the schema once, and change nothing when applied again", async () => {
    const { migrator, migratePool } = await freshDatabase();
    await expect(checkSchema(migrator)).rejects.toThrow(/no migrations yet/);
    await applyMigrations(migrator);
    await checkSchema(migrator);
    await applyMigrations(migrator);
    await checkSchema(migrator);
    expect(await count(migratePool, "drizzle.__drizzle_migrations")).toBe(knownMigrations().length);
    for (const table of [
      "catalog_imports",
      "plans",
      "plan_facts",
      "assignments",
      "catalog_current",
    ]) {
      expect(await count(migratePool, table)).toBe(0);
    }
  });

  it("refuse a database a newer build migrated", async () => {
    const { migrator, migratePool } = await freshDatabase();
    await applyMigrations(migrator);
    await migratePool.query(
      "insert into drizzle.__drizzle_migrations (hash, created_at) values ('later', 9999999999999)",
    );
    await expect(checkSchema(migrator)).rejects.toThrow(SchemaError);
    await expect(importCatalog(migrator, fixtureExport())).rejects.toThrow(
      /newer build migrated it/,
    );
  });
});

describe("importing the catalog", () => {
  it("writes the whole export and serves it, and writes nothing the second time", async () => {
    const { migrator, migratePool, app } = await freshDatabase();
    await applyMigrations(migrator);

    const first = await importCatalog(migrator, fixtureExport());
    expect(first).toMatchObject({ status: "imported", plans: 2, newPlanVersions: 2 });
    expect(await count(app, "plans")).toBe(2);
    expect(await count(app, "plan_facts")).toBe(2);
    expect(await count(app, "assignments")).toBe(33);
    expect(await count(app, "scripture_resources")).toBe(2);
    expect(await served(app)).toBe(first.importId);

    const reading = await app.query(
      "select reading, words from assignments where plan_id = 'test-plan' and plan_version = 1 order by position",
    );
    expect(reading.rows).toEqual(
      plan(fixtureExport(), "test-plan").assignments.map(({ reading, words }) => ({
        reading,
        words,
      })),
    );

    const again = await importCatalog(migrator, fixtureExport());
    expect(again).toEqual({ status: "already-current", importId: first.importId });
    expect(await count(migratePool, "catalog_imports")).toBe(1);
    expect(await count(migratePool, "assignments")).toBe(33);
  });

  it("keeps every plan version, and serves an earlier catalog again on rollback", async () => {
    const { migrator, app } = await freshDatabase();
    await applyMigrations(migrator);
    const first = await importCatalog(migrator, fixtureExport());
    const revised = changedExport((c) => {
      const p = plan(c, "test-plan");
      p.version = 2;
      assignment(c, "test-plan", 0).reading = "MRK 1:1-20";
    });
    const second = await importCatalog(migrator, revised);
    expect(second).toMatchObject({ status: "imported", newPlanVersions: 1 });
    expect(await count(app, "plans")).toBe(3);
    expect(await served(app)).toBe(second.importId);

    const rollback = await importCatalog(migrator, fixtureExport());
    expect(rollback).toEqual({ status: "reactivated", importId: first.importId });
    expect(await served(app)).toBe(first.importId);
    const servedPlans = await app.query(
      `select p.plan_id, p.plan_version from catalog_import_plans p
       join catalog_current c on c.import_id = p.import_id order by p.position`,
    );
    expect(servedPlans.rows).toEqual([
      { plan_id: "monthly-plan", plan_version: 1 },
      { plan_id: "test-plan", plan_version: 1 },
    ]);
  });

  it("refuses a changed plan under the same version, and writes none of that import", async () => {
    const { migrator, migratePool } = await freshDatabase();
    await applyMigrations(migrator);
    await importCatalog(migrator, fixtureExport());
    const silent = changedExport((c) => {
      const extra = structuredClone(plan(c, "monthly-plan"));
      extra.id = "another-plan";
      c.plans.unshift(extra);
      assignment(c, "test-plan", 0).reading = "MRK 2";
    });
    await expect(importCatalog(migrator, silent)).rejects.toThrow(ExportError);
    await expect(importCatalog(migrator, silent)).rejects.toThrow(/raises the plan's version/);
    expect(await count(migratePool, "catalog_imports")).toBe(1);
    expect(await count(migratePool, "plans where id = 'another-plan'")).toBe(0);
  });

  it("refuses an export that fails its checks before touching the database", async () => {
    const { migrator, migratePool } = await freshDatabase();
    await applyMigrations(migrator);
    const pending = changedExport((c) => (plan(c, "test-plan").rightsStatus = "pending"));
    await expect(importCatalog(migrator, pending)).rejects.toThrow(/is pending/);
    expect(await count(migratePool, "catalog_imports")).toBe(0);
  });

  it("imports one export once when two jobs race", async () => {
    const { migrator, name } = await freshDatabase();
    await applyMigrations(migrator);
    const otherPool = new pg.Pool({ database: name, user: "daybyword_migrate" });
    pools.push(otherPool);
    const results = await Promise.all([
      importCatalog(migrator, fixtureExport()),
      importCatalog(database(otherPool), fixtureExport()),
    ]);
    expect(results.map((r) => r.status).sort()).toEqual(["already-current", "imported"]);
  });
});

describe("the database's rules", () => {
  it("never changes or removes an imported row", async () => {
    const { migrator, migratePool } = await freshDatabase();
    await applyMigrations(migrator);
    await importCatalog(migrator, fixtureExport());
    await expect(migratePool.query("update plans set title = 'Changed'")).rejects.toThrow(
      /immutable/,
    );
    await expect(migratePool.query("delete from assignments")).rejects.toThrow(/immutable/);
    await expect(migratePool.query("delete from catalog_imports")).rejects.toThrow(/immutable/);
    await expect(migratePool.query("truncate plans cascade")).rejects.toThrow(/immutable/);
  });

  it("lets the web server read the catalog and nothing more", async () => {
    const { migrator, app } = await freshDatabase();
    await applyMigrations(migrator);
    const { importId } = await importCatalog(migrator, fixtureExport());
    expect(await count(app, "plans")).toBe(2);
    await expect(app.query("insert into catalog_current (import_id) values (1)")).rejects.toThrow(
      /permission denied/,
    );
    await expect(
      app.query("update catalog_current set import_id = $1", [importId]),
    ).rejects.toThrow(/permission denied/);
    await expect(app.query("create table mine (x int)")).rejects.toThrow(/permission denied/);
    await expect(app.query("select * from drizzle.__drizzle_migrations")).rejects.toThrow(
      /permission denied/,
    );
  });
});
