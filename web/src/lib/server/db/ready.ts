// Whether the web server can serve: its database answers, as the web's own
// role, and a catalog has been imported and made current (docs/deploy.md,
// "Health"). The migration job checks the schema before a release is
// activated; this checks only what the read-only web role can see. Without
// DBW_DATABASE_URL (local work, `make check`'s smoke test) there is no
// database to wait for.
import pg from "pg";

let pool: pg.Pool | undefined;

/** True when ready; never throws, and says nothing about why to the caller's client. */
export async function databaseReady(
  url: string | undefined = process.env["DBW_DATABASE_URL"],
): Promise<boolean> {
  if (url === undefined || url === "") return true;
  pool ??= new pg.Pool({
    connectionString: url,
    max: 2,
    connectionTimeoutMillis: 2_000,
    idleTimeoutMillis: 30_000,
  });
  try {
    const result = await pool.query("select 1 from catalog_current limit 1");
    return result.rowCount === 1;
  } catch {
    return false;
  }
}

/** Closes the pool, for tests and shutdown. */
export async function closeReadiness(): Promise<void> {
  await pool?.end();
  pool = undefined;
}
