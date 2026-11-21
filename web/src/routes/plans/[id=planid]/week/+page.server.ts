// A plan's week from a start date, a placeholder until printable weeks are
// built (Phase 13). The start is for display only, and kept only when it
// is a date written YYYY-MM-DD (docs/urls.md). An id that is no plan in the
// catalog is not found.
import { error } from "@sveltejs/kit";
import { startDate } from "#lib/reference.ts";
import { servedCatalog } from "#lib/server/catalog/read.ts";

export const load = async ({ params, url }: { params: { id: string }; url: URL }) => {
  const catalog = await servedCatalog();
  const entry = catalog?.plans.find((plan) => plan.id === params.id);
  if (!entry) error(404);
  return {
    section: "plans" as const,
    id: params.id,
    title: entry.title,
    start: startDate(url.searchParams.get("start")),
  };
};
