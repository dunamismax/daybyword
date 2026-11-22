// A calendar file of one plan's readings ahead, worked out from the journal
// the browser sends (BUILD.md P13.4, docs/decisions.md E59): POST { events,
// today, enrollment, names } as JSON, answered with iCalendar text for
// /assets/reading.js to save. Nothing is kept.
import { namingConventions, type NamingConvention } from "#lib/domain/index.ts";
import { servedCatalog } from "#lib/server/catalog/read.ts";
import { calendarFor, journalRequest, ReadingRequestError } from "#lib/server/reading.ts";
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
    const enrollment = fields["enrollment"];
    if (typeof enrollment !== "string") throw new ReadingRequestError("enrollment is not an id");
    const { file } = calendarFor(catalog, journal, today, enrollment, {
      convention: namingConventions.includes(names as NamingConvention)
        ? (names as NamingConvention)
        : "common",
      stamp: new Date().toISOString(),
    });
    return new Response(file, {
      headers: {
        "Content-Type": "text/calendar; charset=utf-8",
        "Content-Disposition": 'attachment; filename="day-by-word.ics"',
        "Cache-Control": "no-store",
      },
    });
  } catch (error) {
    if (error instanceof ReadingRequestError) return refused(422, error.message);
    throw error;
  }
};
