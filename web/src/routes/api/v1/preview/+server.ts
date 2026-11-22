// What a finish date asks, before the reader starts the plan (BUILD.md
// P8.2b, P8.10d; docs/decisions.md E52): POST { events, today, action } as
// JSON, the action a start would send, answered with the load in words and,
// when it is beyond the reader's limit, the later date that fits. Nothing
// is kept, and nothing is started.
import { servedCatalog } from "#lib/server/catalog/read.ts";
import { ReadingRequestError, startPreview } from "#lib/server/reading.ts";
import { readJSON, refused } from "../request.ts";

export const POST = async ({ request }: { request: Request }) => {
  const catalog = await servedCatalog();
  if (!catalog) return refused(503, "noCatalog");
  const body = await readJSON(request);
  if (body instanceof Response) return body;
  try {
    return new Response(JSON.stringify(startPreview(body, catalog, new Date()) ?? {}), {
      headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
    });
  } catch (error) {
    if (error instanceof ReadingRequestError) return refused(422, error.message);
    throw error;
  }
};
