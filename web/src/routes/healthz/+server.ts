// The deploy's readiness check (docs/deploy.md, the host's web platform
// contract): the commit this release was built from, and whether the
// database answers the web's own read-only role with a current catalog (a
// real query, web/src/lib/server/db/ready.ts). 503 when it does not; no
// detail leaves the server. Without a database configured (local work) the
// answer has no database field. Never cached.
import type { RequestHandler } from "@sveltejs/kit";
import { databaseReady } from "#lib/server/db/ready.ts";
import { revision } from "#lib/server/revision.ts";

export const prerender = false;

const headers = { "Content-Type": "application/json", "Cache-Control": "no-store" };

export const GET: RequestHandler = async () => {
  const body: Record<string, string> = { status: "ok", revision: revision() ?? "development" };
  if (process.env["DATABASE_URL"] === undefined || process.env["DATABASE_URL"] === "") {
    return new Response(JSON.stringify(body), { status: 200, headers });
  }
  if (await databaseReady()) {
    return new Response(JSON.stringify({ ...body, database: "ok" }), { status: 200, headers });
  }
  return new Response(JSON.stringify({ ...body, status: "unavailable", database: "failed" }), {
    status: 503,
    headers,
  });
};
