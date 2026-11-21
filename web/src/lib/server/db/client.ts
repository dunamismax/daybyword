// The server's PostgreSQL connection (server-only; never imported by a
// browser script or exposed to the Apple app, AGENTS.md §5). The URL comes
// from DATABASE_URL (/etc/web-apps/daybyword/web.env or migration.env on the
// server); without it, pg reads the standard PG* variables. With an owner
// role (DB_OWNER_ROLE, set only in migration.env), every connection starts as
// that role: the migration login may create and change tables only as the
// owner, and the owner itself cannot log in. The role is set in the
// connection's startup options, so the server refuses the connection outright
// when the login may not become it.
import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import * as schema from "./schema.ts";

export function createPool(
  url: string | undefined = process.env["DATABASE_URL"],
  ownerRole: string | undefined = process.env["DB_OWNER_ROLE"] || undefined,
): pg.Pool {
  const config: pg.PoolConfig = url === undefined ? {} : { connectionString: url };
  if (ownerRole !== undefined) {
    if (!/^[a-z_][a-z0-9_]*$/.test(ownerRole)) throw new Error("DB_OWNER_ROLE is not a role name");
    config.options = `-c role=${ownerRole}`;
  }
  return new pg.Pool(config);
}

export const database = (pool: pg.Pool) => drizzle({ client: pool, schema, casing: "snake_case" });
export type Database = ReturnType<typeof database>;
