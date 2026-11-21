// Plans: the catalog's plans, read from PostgreSQL and rendered on the
// server (docs/web.md). With no database there are none to show.
import { planList } from "#lib/server/catalog/present.ts";
import { servedCatalog } from "#lib/server/catalog/read.ts";

export const load = async () => {
  const catalog = await servedCatalog();
  return { section: "plans" as const, plans: catalog ? planList(catalog) : [] };
};
