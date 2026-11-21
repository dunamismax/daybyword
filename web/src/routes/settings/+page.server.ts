// Settings (BUILD.md P2.11). The choices live in this browser's own storage,
// restored and kept by /assets/settings.js; the server only adds the version
// (DBW_COMMIT, or the release's REVISION on the server).
import { revision } from "#lib/server/revision.ts";
import { text } from "#lib/strings.ts";

export const load = () => {
  const commit = revision();
  return {
    section: "settings" as const,
    version: commit
      ? text("settings.version", { version: commit.slice(0, 12) })
      : text("settings.development-version"),
  };
};
