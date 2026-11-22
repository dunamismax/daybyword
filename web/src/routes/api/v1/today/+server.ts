// Today, worked out from the journal the browser sends (BUILD.md P8.10c,
// docs/decisions.md E52): POST { events, today, names, way, translation } as JSON, answered
// with Today's cards as HTML for /assets/reading.js to insert. Nothing is
// kept, and the log line has the route and status only (E38).
import { render } from "svelte/server";
import TodayCards from "#lib/components/TodayCards.svelte";
import { servedCatalog } from "#lib/server/catalog/read.ts";
import {
  journalRequest,
  ReadingRequestError,
  todayPage,
  type ReadingOptions,
} from "#lib/server/reading.ts";
import {
  addDays,
  civilDateText,
  namingConventions,
  type CivilDate,
  type NamingConvention,
} from "#lib/domain/index.ts";
import { readJSON, refused } from "../request.ts";

export const POST = async ({ request }: { request: Request }) => {
  const catalog = await servedCatalog();
  if (!catalog) return refused(503, "noCatalog");
  const body = await readJSON(request);
  if (body instanceof Response) return body;
  try {
    const { journal, today } = journalRequest(body, catalog);
    // How the reader reads, from this browser's settings (settings.json).
    const fields = body as Record<string, unknown>;
    const names = fields["names"];
    const way = fields["way"];
    const translation = Number(fields["translation"]);
    const options: ReadingOptions = {
      convention: namingConventions.includes(names as NamingConvention)
        ? (names as NamingConvention)
        : "common",
      way: way === "youVersion" || way === "otherApp" ? way : "physicalBible",
      ...(Number.isInteger(translation) && translation > 0 ? { translation } : {}),
      ...(typeof fields["lastAction"] === "string" ? { lastAction: fields["lastAction"] } : {}),
    };
    const page = (date: CivilDate) => {
      const { cards, rhythm } = todayPage(catalog, journal, date, options);
      return cards.length > 0
        ? render(TodayCards, { props: { cards, ...(rhythm ? { rhythm } : {}) } }).body
        : "";
    };
    // Today, and the six days after it as things stand now, which the
    // browser keeps for when it is offline (P8.11, E53).
    const ahead = [1, 2, 3, 4, 5, 6].map((days) => {
      const date = addDays(today, days);
      return { date: civilDateText(date), html: page(date) };
    });
    return new Response(JSON.stringify({ html: page(today), ahead }), {
      headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
    });
  } catch (error) {
    if (error instanceof ReadingRequestError) return refused(422, error.message);
    throw error;
  }
};
