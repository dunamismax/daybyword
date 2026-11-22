// The privacy policy (BUILD.md P16.3), with the statement of cookies and
// browser storage (P16.4), as the owner approved it on 2026-11-22 from
// docs/legal/privacy.md. Keep it true: it says what the code and the server
// do, and nothing more.
import { siteImage, type Share } from "#lib/server/share.ts";
import { text } from "#lib/strings.ts";

export const load = () => {
  const share: Share = {
    title: text("privacy.title"),
    description: text("privacy.description"),
    path: "/privacy",
    image: siteImage(),
  };
  return { share };
};
