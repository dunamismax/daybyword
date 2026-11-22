// A plan's week from a start date, as a checklist to print (BUILD.md
// P8.10b). The start is for display only, and kept only when it is a date
// written YYYY-MM-DD (docs/urls.md); without one the page shows the plan's
// sample week. `size=large` sets the checklist in large print (P13.1), for
// display only like the start. An id that is no plan in the catalog is not
// found.
import { error } from "@sveltejs/kit";
import { startDate } from "#lib/reference.ts";
import { planWeek } from "#lib/server/catalog/present.ts";
import { servedCatalog } from "#lib/server/catalog/read.ts";

export const load = async ({ params, url }: { params: { id: string }; url: URL }) => {
  const catalog = await servedCatalog();
  const entry = catalog?.plans.find((plan) => plan.id === params.id);
  if (!catalog || !entry) error(404);
  return {
    section: "plans" as const,
    week: planWeek(catalog, entry, startDate(url.searchParams.get("start"))),
    large: url.searchParams.get("size") === "large",
  };
};
