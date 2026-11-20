// Settings (BUILD.md P2.11). The choices live in this browser's own storage,
// restored and kept by /assets/settings.js; the server only adds the version.
import { DBW_COMMIT } from "$app/env/private";
import { text } from "#lib/strings.ts";

export const load = () => ({
  section: "settings" as const,
  version: DBW_COMMIT
    ? text("settings.version", { version: DBW_COMMIT.slice(0, 12) })
    : text("settings.development-version"),
});
