// The web's interface text and the settings kept in the browser
// (tests/fixtures/settings.json, shared with the app).
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  BookRegistry,
  parseReading,
  ReferenceFormatter,
  Versification,
} from "#lib/domain/index.ts";
import { referenceOf, startDate } from "#lib/reference.ts";
import { settings } from "#lib/settings.ts";
import { storedItems } from "#lib/storage.ts";
import {
  englishStrings,
  listText,
  minutesRangeText,
  text,
  workloadRangeText,
  workloadText,
} from "#lib/strings.ts";

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

  it("gives SvelteKit's last-resort error page the table's words (P16.8)", () => {
    const page = read("web/src/error.html").replace(/\s+/g, " ");
    for (const key of [
      "component.error-title",
      "component.error-message",
      "site.go-to-today",
    ] as const) {
      expect(page, key).toContain(englishStrings[key]);
    }
  });

  it("fills placeholders, and says estimates vary", () => {
    expect(text("site.page-title", { page: "Today" })).toBe("Today · Day by Word");
    expect(workloadText(1)).toBe("About 1 minute. Estimates vary.");
    expect(workloadText(12)).toBe("About 12 minutes. Estimates vary.");
  });

  it("gives a workload as a range, or one number when both ends are the same", () => {
    expect(workloadRangeText([9, 11])).toBe("About 9–11 minutes. Estimates vary.");
    expect(workloadRangeText([3, 3])).toBe("About 3 minutes. Estimates vary.");
    expect(workloadRangeText([1, 1])).toBe("About 1 minute. Estimates vary.");
    expect(minutesRangeText([9, 11])).toBe("About 9–11 minutes");
    expect(minutesRangeText([3, 3])).toBe("About 3 minutes");
    expect(minutesRangeText([1, 1])).toBe("About 1 minute");
    expect(text("component.estimates-vary")).toMatch(/^Estimates vary/);
  });

  it("writes a list in words", () => {
    expect(listText([])).toBe("");
    expect(listText(["Proverbs"])).toBe("Proverbs");
    expect(listText(["Ruth", "Jonah"])).toBe("Ruth and Jonah");
    expect(listText(["Matthew", "Mark", "Luke", "John"])).toBe("Matthew, Mark, Luke, and John");
  });

  it("has no key whose text is only a placeholder, which would allow any words on a page", () => {
    for (const [key, english] of Object.entries(englishStrings)) {
      expect(english.replace(/\{[a-z]+\}/g, "").trim(), key).not.toBe("");
    }
  });

  it("follows the voice: no exclamation marks, and nothing a record cannot say", () => {
    for (const [key, english] of Object.entries(englishStrings)) {
      expect(english, key).not.toContain("!");
      expect(english, key).not.toMatch(/\b(streak|behind|missed|failed|faithful)/i);
    }
  });
});

describe("a week's start", () => {
  it("is kept only when it is a date", () => {
    expect(startDate("2027-01-04")).toBe("2027-01-04");
    for (const other of [
      null,
      "next-week",
      "2027-1-4",
      "2027/01/04",
      "２０２７-01-04",
      "2027-02-30",
    ]) {
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
      if (setting.applied) expect(theme).toContain(`"${setting.key}"`);
      expect(keeper).toContain(`"${setting.key}"`);
      expect(keeper).toContain(`"${setting.name}"`);
    }
  });
});

describe("a reference, said aloud", () => {
  const english = new Versification("english", read("catalog/scripture/versification/english.tsv"));
  const formatter = new ReferenceFormatter(
    new BookRegistry(read("catalog/scripture/books.json")),
    english,
  );
  const said = (reading: string) => referenceOf(parseReading(reading, english), formatter);

  it("names chapters and verses in words, beside what is shown", () => {
    for (const [reading, display, spoken] of [
      ["MAT 1-3", "Matthew 1–3", "Matthew, chapters 1 to 3"],
      ["PRO 7", "Proverbs 7", "Proverbs, chapter 7"],
      ["MRK 4:1-20", "Mark 4:1–20", "Mark, chapter 4, verses 1 to 20"],
      ["JHN 3:16", "John 3:16", "John, chapter 3, verse 16"],
      ["JHN 3:16-4:3", "John 3:16–4:3", "John, chapter 3, verse 16, to chapter 4, verse 3"],
      ["PSA 23", "Psalm 23", "Psalm 23"],
      ["PSA 120-122", "Psalms 120–122", "Psalms 120 to 122"],
      ["JUD 1", "Jude", "Jude"],
      ["JUD 1:3-5", "Jude 3–5", "Jude, verses 3 to 5"],
      ["JUD 1:3", "Jude 3", "Jude, verse 3"],
      ["OBA 1; JON 1-2", "Obadiah; Jonah 1–2", "Obadiah; then Jonah, chapters 1 to 2"],
    ] as const) {
      expect(said(reading), reading).toEqual({ display, spoken });
    }
  });
});

describe("the privacy policy's browser storage (P16.4)", () => {
  it("lists every name the code stores in the browser, and sets no cookie", () => {
    const listed = new Set(storedItems.map((item) => item.name));
    const code = [
      read("web/static/assets/reading.js"),
      read("web/static/assets/settings.js"),
      read("web/static/assets/theme.js"),
      read("web/src/service-worker/index.ts"),
    ].join("\n");
    const keys = new Set([...code.matchAll(/"(dbw\.[a-z-]+)"/g)].map((match) => match[1]));
    expect(keys.size).toBeGreaterThan(0);
    for (const key of keys) expect(listed, key).toContain(key);
    for (const store of [...code.matchAll(/Store = "([a-z]+)"|const store = "([a-z]+)"/g)]) {
      const name = store[1] ?? store[2];
      expect(listed, name).toContain(`day-by-word / ${name}`);
    }
    expect(code).toContain("`day-by-word-${version}`");
    expect(code).not.toMatch(/document\.cookie/);
  });
});
