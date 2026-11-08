// The server's PostgreSQL connection (server-only; never imported by a
// browser script or exposed to the Apple app, AGENTS.md §5). The URL comes
// from DBW_DATABASE_URL; without it, pg reads the standard PG* variables.
import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import * as schema from "./schema.ts";

export function createPool(url: string | undefined = process.env["DBW_DATABASE_URL"]): pg.Pool {
  return new pg.Pool(url === undefined ? {} : { connectionString: url });
}

export const database = (pool: pg.Pool) => drizzle({ client: pool, schema, casing: "snake_case" });
export type Database = ReturnType<typeof database>;
