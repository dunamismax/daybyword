// The commit this server was built from (docs/deploy.md): DBW_COMMIT when it
// is set (the production tests), otherwise the release directory's REVISION
// file, which the systemd unit's working directory holds on the server.
// Undefined for a local build. Read once.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { DBW_COMMIT } from "$app/env/private";

let cached: { value: string | undefined } | undefined;

export function revision(): string | undefined {
  if (cached) return cached.value;
  let value = DBW_COMMIT;
  if (value === undefined) {
    try {
      const text = readFileSync(join(process.cwd(), "REVISION"), "utf8").trim();
      if (/^[0-9a-f]{40}$/.test(text)) value = text;
    } catch {
      // No REVISION outside a release.
    }
  }
  cached = { value };
  return value;
}
