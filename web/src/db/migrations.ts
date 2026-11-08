// Applying the reviewed SQL migrations in drizzle/, and checking that a
// database's schema is the one this build expects (BUILD.md PM.14). Run by the
// one-shot migration job under the deploy lock (scripts/db-migrate.ts), never
// on a request.
import { readFileSync } from "node:fs";
import { sql } from "drizzle-orm";
import { migrate } from "drizzle-orm/node-postgres/migrator";
import type { Database } from "./client.ts";

export const migrationsFolder = new URL("../../drizzle/", import.meta.url).pathname;

interface Journal {
  entries: { idx: number; when: number; tag: string }[];
}

/** The migrations this build carries, oldest first. */
export function knownMigrations(): { tag: string; when: number }[] {
  const journal = JSON.parse(
    readFileSync(`${migrationsFolder}meta/_journal.json`, "utf8"),
  ) as Journal;
  return journal.entries.map(({ tag, when }) => ({ tag, when }));
}

export class SchemaError extends Error {
  override name = "SchemaError";
}

/** Applies every migration not yet applied; applying them again changes nothing. */
export async function applyMigrations(db: Database): Promise<void> {
  await migrate(db, { migrationsFolder });
}

/**
 * Throws unless the database has exactly this build's migrations: none
 * missing (run the migration job) and none unknown (a newer build migrated
 * it, so this build must not write to it).
 */
export async function checkSchema(db: Database): Promise<void> {
  const known = knownMigrations();
  const table = await db.execute<{ exists: boolean }>(
    sql`select to_regclass('drizzle.__drizzle_migrations') is not null as exists`,
  );
  if (!table.rows[0]?.exists) {
    throw new SchemaError("the database has no migrations yet: run make db-migrate first");
  }
  const applied = await db.execute<{ created_at: string }>(
    sql`select created_at from drizzle.__drizzle_migrations order by created_at`,
  );
  const appliedTimes = applied.rows.map((r) => Number(r.created_at));
  const knownTimes = new Set(known.map((m) => m.when));
  const unknown = appliedTimes.filter((t) => !knownTimes.has(t));
  if (unknown.length > 0) {
    throw new SchemaError(
      `the database has ${unknown.length} migration(s) this build does not know: a newer build migrated it`,
    );
  }
  const missing = known.filter((m) => !appliedTimes.includes(m.when));
  if (missing.length > 0) {
    throw new SchemaError(
      `the database is missing migration ${missing[0]?.tag ?? ""}: run make db-migrate first`,
    );
  }
}
