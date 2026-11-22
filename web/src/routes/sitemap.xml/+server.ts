// The sitemap (BUILD.md P9.9): the public pages, the home page, Plans,
// Support (P16.2), Sources and the criteria (P16.5), and each plan's page, by their address on daybyword.com, for search engines
// once the site opens to them (P18.5; until then robots.txt blocks them).
import { servedCatalog } from "#lib/server/catalog/read.ts";
import { siteOrigin } from "#lib/site.ts";

const escaped = (text: string) =>
  text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");

export const GET = async () => {
  const catalog = await servedCatalog();
  const paths = [
    "/",
    "/plans",
    "/support",
    "/sources",
    "/criteria",
    ...(catalog?.plans.map((plan) => `/plans/${plan.id}`) ?? []),
  ];
  const urls = paths.map((path) => `  <url><loc>${escaped(siteOrigin + path)}</loc></url>`);
  const body = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    ...urls,
    "</urlset>",
    "",
  ].join("\n");
  return new Response(body, { headers: { "content-type": "application/xml; charset=utf-8" } });
};
