// The sources behind the catalog, for the sources page (BUILD.md P16.5).
// catalog/SOURCES.md is read when the site is built, and its entries are
// taken as the catalog compiler takes them (catalog/SOURCES.md, "The
// schema"): the id and title from each `## id: title` heading, the status
// from the first word in backticks on its Status line. The reader's words
// for each data source, and the credit its basis asks for, are the string
// table's; a cleared source without them stops the page, so a new source
// cannot be served without its credit.
import sourcesFile from "../../../../../catalog/SOURCES.md?raw";
import type { StringKey } from "#lib/strings.ts";

export interface SourceEntry {
  readonly id: string;
  readonly title: string;
  readonly status: string;
}

/** Every entry in SOURCES.md, in its order. */
export function sourceEntries(markdown: string = sourcesFile): SourceEntry[] {
  return markdown.split(/^## /m).flatMap((block) => {
    const heading = /^([a-z0-9-]+): (.+)$/m.exec(block.split("\n")[0] ?? "");
    const status = /^- \*\*Status:\*\*[^`\n]*`([a-z]+)`/m.exec(block)?.[1];
    return heading?.[1] && heading[2] && status
      ? [{ id: heading[1], title: heading[2].trim(), status }]
      : [];
  });
}

/** A credit a source's basis asks for: words, the link they carry, and the licence. */
export interface Credit {
  readonly text: StringKey;
  readonly href: string;
  readonly licence: StringKey;
}

/** What each data source gives Day by Word, in the reader's words, and its credit. */
export const dataSources: Readonly<Record<string, { about: StringKey; credit?: Credit }>> = {
  "kjv-1769-ebible": { about: "sources.kjv" },
  "web-ebible": { about: "sources.web" },
  "stepbible-tvtms": {
    about: "sources.stepbible",
    credit: {
      text: "sources.stepbible-credit",
      href: "https://www.STEPBible.org",
      licence: "sources.cc-by",
    },
  },
};
