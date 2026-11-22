// Support (BUILD.md P16.2): how to reach Day by Word, how to report a
// reading that looks wrong, what is kept about a reader, and questions
// people ask. A public page, with a description and a link preview.
import { siteImage, type Share } from "#lib/server/share.ts";
import { text } from "#lib/strings.ts";

export const load = () => {
  const share: Share = {
    title: text("support.title"),
    description: text("support.description"),
    path: "/support",
    image: siteImage(),
  };
  return { share };
};
