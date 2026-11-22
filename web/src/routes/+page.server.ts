// The home page: what Day by Word is, the plans actually in the catalog
// (never promised ones), the independence statement, and the way into Today
// (BUILD.md P16.1). Its share data gives the site's line and image to link
// previews (P9.9). With no database there are no plans to list.
import { planList } from "#lib/server/catalog/present.ts";
import { servedCatalog } from "#lib/server/catalog/read.ts";
import { siteImage, type Share } from "#lib/server/share.ts";
import { text } from "#lib/strings.ts";

export const load = async () => {
  const catalog = await servedCatalog();
  const share: Share = {
    title: text("site.name"),
    description: `${text("site.tagline")} ${text("site.line")}`,
    path: "/",
    image: siteImage(),
  };
  return { plans: catalog ? planList(catalog) : [], share };
};
