// The accessibility statement (BUILD.md P16.6): the aim (WCAG 2.2 AA),
// what has been tested, what has not yet, and how to report a barrier.
// Keep "What has been tested" true: it names only checks that have run
// (docs/browsers.md, BUILD.md's Results), and Phase 17 moves the gaps.
import { siteImage, type Share } from "#lib/server/share.ts";
import { text } from "#lib/strings.ts";

export const load = () => {
  const share: Share = {
    title: text("accessibility.title"),
    description: text("accessibility.description"),
    path: "/accessibility",
    image: siteImage(),
  };
  return { share };
};
