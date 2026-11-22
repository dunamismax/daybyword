// A plan's page, from the served catalog. An id that is no plan in it is
// not found (docs/urls.md).
import { error } from "@sveltejs/kit";
import { planPage } from "#lib/server/catalog/present.ts";
import { servedCatalog } from "#lib/server/catalog/read.ts";
import { planImage, type Share } from "#lib/server/share.ts";

export const load = async ({ params }: { params: { id: string } }) => {
  const catalog = await servedCatalog();
  const entry = catalog?.plans.find((plan) => plan.id === params.id);
  if (!catalog || !entry) error(404);
  const share: Share = {
    title: entry.title,
    description: entry.summary,
    path: `/plans/${entry.id}`,
    image: planImage(entry.id),
  };
  return { section: "plans" as const, plan: planPage(catalog, entry), share };
};
