// The site's one public address (D1), wherever a page is served from, and
// what a public page tells search engines and link previews about itself
// (BUILD.md P9.9). The server fills a page's Share (#lib/server/share.ts);
// the layout writes it into the page's head.
export const siteOrigin = "https://daybyword.com";

export interface Share {
  readonly title: string;
  readonly description: string;
  /** The page's path, from the site's root. */
  readonly path: string;
  /** The image's path, from the site's root, and its size. */
  readonly image: { readonly path: string; readonly width: number; readonly height: number };
}
