// Progress, worked out from the journal the browser sends (BUILD.md P8.12,
// docs/decisions.md E52): POST { events, today, names, streak } as JSON, answered
// with the Progress view as HTML for /assets/reading.js to insert. Nothing
// is kept.
import { render } from "svelte/server";
import ProgressView from "#lib/components/ProgressView.svelte";
import { namingConventions, type NamingConvention } from "#lib/domain/index.ts";
import { servedCatalog } from "#lib/server/catalog/read.ts";
import { journalRequest, progressPage, ReadingRequestError } from "#lib/server/reading.ts";
import { readJSON, refused } from "../request.ts";

export const POST = async ({ request }: { request: Request }) => {
  const catalog = await servedCatalog();
  if (!catalog) return refused(503, "noCatalog");
  const body = await readJSON(request);
  if (body instanceof Response) return body;
  try {
    const { journal, today } = journalRequest(body, catalog);
    const fields = body as Record<string, unknown>;
    const names = fields["names"];
    const progress = progressPage(catalog, journal, today, {
      convention: namingConventions.includes(names as NamingConvention)
        ? (names as NamingConvention)
        : "common",
      // The streak only when the reader turned it on (D17).
      streak: fields["streak"] === "on",
    });
    const html =
      progress.plans.length > 0 ? render(ProgressView, { props: { progress } }).body : "";
    return new Response(JSON.stringify({ html }), {
      headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
    });
  } catch (error) {
    if (error instanceof ReadingRequestError) return refused(422, error.message);
    throw error;
  }
};
