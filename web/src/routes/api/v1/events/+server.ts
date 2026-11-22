// A new journal event for what the reader did (BUILD.md P8.10c,
// docs/decisions.md E52): POST { events, today, zone, action } as JSON,
// answered with the new events in their wire form, which the browser adds
// to its own journal. The server makes the id and checks the event against
// the journal sent, and keeps nothing.
import { servedCatalog } from "#lib/server/catalog/read.ts";
import { newEvents, ReadingRequestError } from "#lib/server/reading.ts";
import { readJSON, refused } from "../request.ts";

export const POST = async ({ request }: { request: Request }) => {
  const catalog = await servedCatalog();
  if (!catalog) return refused(503, "noCatalog");
  const body = await readJSON(request);
  if (body instanceof Response) return body;
  try {
    const events = newEvents(body, catalog, new Date());
    return new Response(JSON.stringify({ events }), {
      status: 201,
      headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
    });
  } catch (error) {
    if (error instanceof ReadingRequestError) return refused(422, error.message);
    throw error;
  }
};
