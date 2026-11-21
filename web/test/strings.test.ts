// The web's interface text and the settings kept in the browser
// (tests/fixtures/settings.json, shared with the app).
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { startDate } from "#lib/reference.ts";
import { settings } from "#lib/settings.ts";
import { englishStrings, text, workloadText } from "#lib/strings.ts";

const repository = new URL("../../", import.meta.url);
const read = (path: string) => readFileSync(new URL(path, repository), "utf8");

describe("the interface text", () => {
  it("has English for every key, trimmed, with every placeholder named", () => {
    for (const [key, english] of Object.entries(englishStrings)) {
      expect(english.trim(), key).not.toBe("");
      expect(english.trim(), key).toBe(english);
      expect(english, key).not.toContain("{}");
      expect(key, key).toMatch(/^[a-z-]+\.[a-z-]+$/);
    }
  });

  it("fills placeholders, and says estimates vary", () => {
    expect(text("site.page-title", { page: "Today" })).toBe("Today · Day by Word");
    expect(workloadText(1)).toBe("About 1 minute. Estimates vary.");
    expect(workloadText(12)).toBe("About 12 minutes. Estimates vary.");
  });

  it("follows the voice: no exclamation marks, and nothing a record cannot say", () => {
    for (const [key, english] of Object.entries(englishStrings)) {
      expect(english, key).not.toContain("!");
      expect(english, key).not.toMatch(/\b(streak|behind|missed|failed|faithful)/i);
    }
  });
});

describe("a week's start", () => {
  it("is kept only when it looks like a date", () => {
    expect(startDate("2027-01-04")).toBe("2027-01-04");
    for (const other of [null, "next-week", "2027-1-4", "2027/01/04", "２０２７-01-04"]) {
      expect(startDate(other), String(other)).toBeUndefined();
    }
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
