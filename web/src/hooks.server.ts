// Marks each response with the route pattern that answered it (never the
// concrete address), which server.ts logs and removes before the response is
// sent; and keeps pages from being stored without revalidation. Personal
// records never reach the server at 1.0 (D39), so nothing here is private.
import type { Handle } from "@sveltejs/kit/hooks";

const routeHeader = "x-dbw-route";

export const handle: Handle = async ({ event, resolve }) => {
  const response = await resolve(event);
  try {
    response.headers.set(routeHeader, event.route.id ?? "unmatched");
    if (!response.headers.has("cache-control")) response.headers.set("cache-control", "no-cache");
    if (response.headers.get("content-type") === "text/html") {
      response.headers.set("content-type", "text/html; charset=utf-8");
    }
  } catch {
    // An immutable response (a redirect made with Response.redirect) keeps its headers.
  }
  return response;
};
