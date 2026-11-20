// The server's settings from the environment (SvelteKit 3's explicit
// environment variables), checked at start-up rather than guessed, as the
// Swift server's ServerConfiguration did. All are private: none reaches the
// browser.
import { defineEnvVars } from "@sveltejs/kit/env";

export const variables = defineEnvVars({
  /** `development` serves the component gallery at /dev/components; production by default. */
  DBW_ENV: {
    schema: (value: string | undefined): "development" | "production" => {
      if (value === undefined || value === "" || value === "production") return "production";
      if (value === "development") return "development";
      throw new Error(`DBW_ENV must be development or production, not ${value}`);
    },
  },
  /** The deployed commit, shown in Settings; none shows "Development build". */
  DBW_COMMIT: {
    schema: (value: string | undefined): string | undefined => {
      if (value === undefined || value === "") return undefined;
      if (!/^[0-9a-fA-F]{1,40}$/.test(value)) {
        throw new Error(`DBW_COMMIT must be a commit hash, not ${value}`);
      }
      return value.toLowerCase();
    },
  },
});
