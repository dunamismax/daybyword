// Sources and permissions (BUILD.md P16.5), generated from the served
// catalog and catalog/SOURCES.md (present.ts, sources.ts). With no
// database there are no plans to list, and the data sources still show.
import { sourcesPage } from "#lib/server/catalog/present.ts";
import { servedCatalog } from "#lib/server/catalog/read.ts";
import { siteImage, type Share } from "#lib/server/share.ts";
import { text } from "#lib/strings.ts";

export const load = async () => {
  const catalog = await servedCatalog();
  const share: Share = {
    title: text("sources.title"),
    description: text("sources.description"),
    path: "/sources",
    image: siteImage(),
  };
  return { sources: catalog ? sourcesPage(catalog) : undefined, share };
};
