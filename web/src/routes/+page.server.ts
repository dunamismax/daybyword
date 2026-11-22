// The home page: what Day by Word is, and the way into Today. Its share data
// gives the site's line and image to link previews (BUILD.md P9.9).
import { siteImage, type Share } from "#lib/server/share.ts";
import { text } from "#lib/strings.ts";

export const load = () => {
  const share: Share = {
    title: text("site.name"),
    description: `${text("site.tagline")} ${text("site.line")}`,
    path: "/",
    image: siteImage(),
  };
  return { share };
};
