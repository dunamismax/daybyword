// The server's PostgreSQL connection (server-only; never imported by a
// browser script or exposed to the Apple app, AGENTS.md §5). The URL comes
// from DATABASE_URL (/etc/web-apps/daybyword/web.env or migration.env on the
// server); without it, pg reads the standard PG* variables. With an owner
// role (DB_OWNER_ROLE, set only in migration.env), every connection becomes
// that role first: the migration login may create and change tables only
// after SET ROLE, and the owner itself cannot log in.
import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import * as schema from "./schema.ts";

export function createPool(
  url: string | undefined = process.env["DATABASE_URL"],
  ownerRole: string | undefined = process.env["DB_OWNER_ROLE"] || undefined,
): pg.Pool {
  const pool = new pg.Pool(url === undefined ? {} : { connectionString: url });
  if (ownerRole !== undefined) {
    // Queued before any query the pool hands the client out for. A login
    // that cannot become the owner is an error, never a silent fallback.
    pool.on("connect", (client) => {
      client
        .query(`set role ${client.escapeIdentifier(ownerRole)}`)
        .catch((error: unknown) => pool.emit("error", error, client));
    });
  }
  return pool;
}

export const database = (pool: pg.Pool) => drizzle({ client: pool, schema, casing: "snake_case" });
export type Database = ReturnType<typeof database>;
