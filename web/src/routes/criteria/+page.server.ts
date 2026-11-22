// How Day by Word chooses its plans (BUILD.md P16.5): the standard every
// plan in the catalog meets, published for readers. Its words are the
// string table's criteria.* keys, the one copy (docs/criteria.md points here).
import { siteImage, type Share } from "#lib/server/share.ts";
import { text } from "#lib/strings.ts";

export const load = () => {
  const share: Share = {
    title: text("criteria.title"),
    description: text("criteria.description"),
    path: "/criteria",
    image: siteImage(),
  };
  return { share };
};
