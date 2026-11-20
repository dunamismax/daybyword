// The health check that Caddy, deploys, and monitoring use. Always rendered
// on demand and never cached (tests/fixtures/routes.json, "/up"). With a
// database configured it answers OK only once the database answers and a
// catalog is current; otherwise 503, with no detail.
import type { RequestHandler } from "@sveltejs/kit";
import { databaseReady } from "#lib/server/db/ready.ts";

export const prerender = false;

const headers = { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store" };

export const GET: RequestHandler = async () =>
  (await databaseReady())
    ? new Response("OK\n", { status: 200, headers })
    : new Response("Not ready\n", { status: 503, headers });
