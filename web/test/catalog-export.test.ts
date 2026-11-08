import { describe, expect, it } from "vitest";
import { checkExport, contentSha256, ExportError } from "../src/catalog/export.ts";
import { assignment, changedExport, fixtureExport, plan } from "./helpers.ts";

describe("the catalog export", () => {
  it("accepts the Swift compiler's export, with the same checksum", () => {
    const document = fixtureExport();
    expect(contentSha256(document)).toBe(document.contentSha256);
    const catalog = checkExport(document);
    expect(catalog.plans.map((p) => p.id)).toEqual(["monthly-plan", "test-plan"]);
  });

  it("refuses content that does not match the checksum", () => {
    const document = fixtureExport();
    assignment(document, "test-plan", 0).reading = "MRK 2";
    expect(() => checkExport(document)).toThrow(/does not match its checksum/);
  });

  const refusals: [string, (c: ReturnType<typeof fixtureExport>) => void, RegExp][] = [
    ["another format", (c) => (c.format = "something-else"), /format is not/],
    ["a later format version", (c) => (c.formatVersion = 2), /format 2; this build reads format 1/],
    ["another catalog schema", (c) => (c.schemaVersion = 2), /schema 2; this build reads schema 3/],
    ["a development build", (c) => (c.buildMode = "development"), /only a release build/],
    [
      "pending rights in a release",
      (c) => (plan(c, "test-plan").rightsStatus = "pending"),
      /is pending, so it cannot be served/,
    ],
    [
      "rejected rights",
      (c) => (plan(c, "test-plan").rightsStatus = "rejected"),
      /is rejected, so it cannot be served/,
    ],
    [
      "a plan below reviewed in a release",
      (c) => (plan(c, "test-plan").review = "checked"),
      /below reviewed/,
    ],
    [
      "a coverage claim with omissions",
      (c) => (plan(c, "monthly-plan").facts.omitted = "PRO 31:10-31"),
      /claims books coverage but omits PRO 31:10-31/,
    ],
    ["a plan twice", (c) => c.plans.push(structuredClone(plan(c, "test-plan"))), /appears twice/],
    [
      "assignments out of place",
      (c) => (assignment(c, "test-plan", 1).position = 3),
      /at position 3, not 2/,
    ],
    [
      "a repeated assignment id",
      (c) => (assignment(c, "test-plan", 1).id = 1),
      /assignment id 1 is not unique/,
    ],
    [
      "a number that is not whole",
      (c) => (plan(c, "test-plan").facts.verses = 1.5),
      /facts.verses is not a whole number/,
    ],
    ["missing scripture", (c) => c.scripture.pop(), /scripture is books.json, not/],
  ];
  for (const [what, change, message] of refusals) {
    it(`refuses ${what}`, () => {
      expect(() => checkExport(changedExport(change))).toThrow(ExportError);
      expect(() => checkExport(changedExport(change))).toThrow(message);
    });
  }

  it("accepts a development build only when asked, and its pending rights", () => {
    const development = changedExport((c) => {
      c.buildMode = "development";
      plan(c, "test-plan").rightsStatus = "pending";
      plan(c, "test-plan").review = "checked";
    });
    expect(checkExport(development, { allowDevelopment: true }).buildMode).toBe("development");
  });

  it("refuses what is not an export", () => {
    expect(() => checkExport([])).toThrow(/not a JSON object/);
    expect(() => checkExport({ ...fixtureExport(), plans: {} })).toThrow(/plans are not a list/);
  });
});
