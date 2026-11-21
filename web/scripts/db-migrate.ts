// The one-shot migration job: applies drizzle/'s migrations to the database
// in DATABASE_URL (or the PG* variables), then checks the schema. Run with
// migration.env (the migration login and DB_OWNER_ROLE, which it becomes)
// under the deploy lock, never by the web server.
import { createPool, database } from "#lib/server/db/client.ts";
import { applyMigrations, checkSchema, knownMigrations } from "#lib/server/db/migrations.ts";

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
