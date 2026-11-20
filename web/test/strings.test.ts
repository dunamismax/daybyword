// The web's interface text and settings against the fixtures captured from
// the Swift server (tests/fixtures/strings.json, settings.json).
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { settings } from "#lib/settings.ts";
import { englishStrings, text, workloadText } from "#lib/strings.ts";

const repository = new URL("../../", import.meta.url);
const read = (path: string) => readFileSync(new URL(path, repository), "utf8");

describe("the interface text", () => {
  it("is the Swift server's English table, key for key", () => {
    const fixture = JSON.parse(read("tests/fixtures/strings.json")) as {
      cases: { input: string; output: Record<string, string> }[];
    };
    expect(fixture.cases[0]?.input).toBe("en");
    expect(englishStrings).toEqual(fixture.cases[0]?.output);
  });

  it("fills placeholders, and says estimates vary", () => {
    expect(text("site.page-title", { page: "Today" })).toBe("Today · Day by Word");
    expect(workloadText(1)).toBe("About 1 minute. Estimates vary.");
    expect(workloadText(12)).toBe("About 12 minutes. Estimates vary.");
  });
});

describe("the settings", () => {
  const fixture = JSON.parse(read("tests/fixtures/settings.json")) as {
    settings: {
      name: string;
      values: string[];
      defaultValue: string;
      web: { field: string; storageKey: string };
    }[];
  };

  it("are the fixture's, with their fields, values, defaults and keys", () => {
    expect(
      settings.map((s) => ({ name: s.name, values: s.values, fallback: s.fallback, key: s.key })),
    ).toEqual(
      fixture.settings.map((s) => ({
        name: s.web.field,
        values: s.values,
        fallback: s.defaultValue,
        key: s.web.storageKey,
      })),
    );
  });

  it("are kept and applied by the browser scripts under the same keys", () => {
    const theme = read("web/static/assets/theme.js");
    const keeper = read("web/static/assets/settings.js");
    for (const setting of settings) {
      expect(theme).toContain(`"${setting.key}"`);
      expect(keeper).toContain(`"${setting.key}"`);
      expect(keeper).toContain(`"${setting.name}"`);
    }
  });
});
