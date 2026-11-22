// What a page tells search engines and link previews about itself (BUILD.md
// P9.9): its title, a description in the page's own words, its address on
// daybyword.com (D1), and an image from the owner's files (D19). Images come
// from design/images/manifest.json, so a page never names one that was not
// delivered. No structured data: no schema.org type says what a reading plan
// is without claiming something it is not (docs/decisions.md E55).
import manifest from "../../../../design/images/manifest.json";
import type { Share } from "#lib/site.ts";

export type { Share } from "#lib/site.ts";

interface Asset {
  file: string;
  width?: number;
  height?: number;
  copies?: string[];
}

const webCopies = "web/static";

/** A delivered image's path on the site, from its file in design/images/, or undefined. */
function served(file: string): Share["image"] | undefined {
  const asset = (manifest.assets as Asset[]).find((entry) => entry.file === file);
  const copy = asset?.copies?.find((path) => path.startsWith(`${webCopies}/`));
  if (!asset || !copy || asset.width === undefined || asset.height === undefined) return undefined;
  return { path: copy.slice(webCopies.length), width: asset.width, height: asset.height };
}

/** The site's own image, for pages without one of their own. */
export function siteImage(): Share["image"] {
  const image = served("share.png");
  if (!image) throw new Error("design/images/manifest.json has no web copy of share.png");
  return image;
}

/** A plan's own image, or the site's. */
export function planImage(id: string): Share["image"] {
  return served(`plans/${id}.jpg`) ?? siteImage();
}
