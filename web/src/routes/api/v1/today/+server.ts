// Today, worked out from the journal the browser sends (BUILD.md P8.10c,
// docs/decisions.md E52): POST { events, today, names } as JSON, answered
// with Today's cards as HTML for /assets/reading.js to insert. Nothing is
// kept, and the log line has the route and status only (E38).
import { render } from "svelte/server";
import TodayCards from "#lib/components/TodayCards.svelte";
import { servedCatalog } from "#lib/server/catalog/read.ts";
import { journalRequest, ReadingRequestError, todayCards } from "#lib/server/reading.ts";
import { namingConventions, type NamingConvention } from "#lib/domain/index.ts";
import { readJSON, refused } from "../request.ts";

export const POST = async ({ request }: { request: Request }) => {
  const catalog = await servedCatalog();
  if (!catalog) return refused(503, "noCatalog");
  const body = await readJSON(request);
  if (body instanceof Response) return body;
  try {
    const { journal, today } = journalRequest(body, catalog);
    const names = (body as Record<string, unknown>)["names"];
    const convention = namingConventions.includes(names as NamingConvention)
      ? (names as NamingConvention)
      : "common";
    const cards = todayCards(catalog, journal, today, convention);
    const html = cards.length > 0 ? render(TodayCards, { props: { cards } }).body : "";
    return new Response(JSON.stringify({ html, plans: cards.length }), {
      headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
    });
  } catch (error) {
    if (error instanceof ReadingRequestError) return refused(422, error.message);
    throw error;
  }
};
