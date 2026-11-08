// The health check that Caddy, deploys, and monitoring use. Always rendered
// on demand and never cached (tests/fixtures/routes.json, "/up").
import type { APIRoute } from "astro";

export const prerender = false;

export const GET: APIRoute = () =>
  new Response("OK\n", {
    status: 200,
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
