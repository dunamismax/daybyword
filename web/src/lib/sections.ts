// The site's sections, the same three as the app's tabs plus Settings
// (docs/product.md, Navigation; docs/urls.md).
import { text, type StringKey } from "./strings.ts";

export const sections = ["today", "plans", "progress", "settings"] as const;
export type Section = (typeof sections)[number];

export function sectionPath(section: Section): string {
  return `/${section}`;
}

export function sectionTitle(section: Section): string {
  return text(`section.${section}` as StringKey);
}

/** A page's full title: "Today · Day by Word", or the site's name for the home page. */
export function pageTitle(title?: string): string {
  return title === undefined ? text("site.name") : text("site.page-title", { page: title });
}
