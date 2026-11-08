// The one-shot migration job: applies drizzle/'s migrations to the database
// in DBW_DATABASE_URL (or the PG* variables), then checks the schema. Run as
// daybyword_migrate under the deploy lock, never by the web server.
import { createPool, database } from "../src/db/client.ts";
import { applyMigrations, checkSchema, knownMigrations } from "../src/db/migrations.ts";

const pool = createPool();
try {
  const db = database(pool);
  await applyMigrations(db);
  await checkSchema(db);
  console.log(`db-migrate: the schema is current (${knownMigrations().length} migrations)`);
} catch (error) {
  console.error(`db-migrate: ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 1;
} finally {
  await pool.end();
}
