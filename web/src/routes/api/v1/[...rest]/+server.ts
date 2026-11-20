// /api/v1 is reserved for the app's and the browser's calls (docs/urls.md);
// until an endpoint claims an address, it answers 404 in JSON, never cached.
import type { RequestHandler } from "@sveltejs/kit";

const notFound: RequestHandler = () =>
  new Response(JSON.stringify({ error: "notFound" }), {
    status: 404,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });

export const GET = notFound;
export const HEAD = notFound;
export const POST = notFound;
export const PUT = notFound;
export const PATCH = notFound;
export const DELETE = notFound;
