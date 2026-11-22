// The terms of use (BUILD.md P16.3), as the owner approved them on
// 2026-11-22 from docs/legal/terms.md: Apple's standard EULA for the app,
// and no governing law stated.
import { siteImage, type Share } from "#lib/server/share.ts";
import { text } from "#lib/strings.ts";

export const load = () => {
  const share: Share = {
    title: text("terms.title"),
    description: text("terms.description"),
    path: "/terms",
    image: siteImage(),
  };
  return { share };
};
