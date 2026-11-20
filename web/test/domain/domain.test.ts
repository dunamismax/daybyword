// The TypeScript domain module against the shared fixtures in Node
// (docs/decisions.md E33). The same cases run in a real browser through
// `make test-domain-browser`, and in Swift through FixtureTests.
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  BookRegistry,
  parseReading,
  parseSwiftInt,
  roundHalfAwayFromZero,
  specificationVersion,
  Versification,
  WordCounts,
  workload,
} from "#lib/domain/index.ts";
import {
  checkParity,
  computers,
  domainFixtures,
  type DomainFixture,
  type FixtureFile,
  type Resources,
} from "./parity.ts";

const repository = new URL("../../../", import.meta.url);
const read = (path: string) => readFileSync(new URL(path, repository), "utf8");

function loadResources(): Resources {
  const registry = new BookRegistry(read("catalog/scripture/books.json"));
  const english = new Versification("english", read("catalog/scripture/versification/english.tsv"));
  english.check(registry);
  return {
    registry,
    english,
    counts: new WordCounts(read("catalog/scripture/words/web.tsv"), english),
  };
}

const resources = loadResources();
const fixtures = Object.fromEntries(
  domainFixtures.map((name) => [
    name,
    JSON.parse(read(`tests/fixtures/${name}.json`)) as FixtureFile,
  ]),
) as Record<DomainFixture, FixtureFile>;

describe("the shared fixtures", () => {
  const compute = computers(resources);
  for (const name of domainFixtures) {
    it(`gives Swift's outputs for ${name}`, () => {
      const file = fixtures[name];
      expect(file.fixture).toBe(name);
      expect(file.cases.length).toBeGreaterThan(0);
      file.cases.forEach((testCase, index) => {
        const actual = (compute[name] as (input: unknown) => unknown)(testCase.input);
        expect(actual, `${name} case ${index}: ${JSON.stringify(testCase.input)}`).toEqual(
          testCase.output,
        );
      });
    });
  }

  it("all pass through the comparison the browser uses", () => {
    const report = checkParity(resources, fixtures);
    expect(report.failures).toEqual([]);
    expect(report.cases).toBe(
      domainFixtures.reduce((sum, name) => sum + fixtures[name].cases.length, 0),
    );
  });

  it("are compared closely enough to catch one wrong output", () => {
    const changed = structuredClone(fixtures);
    const first = changed.references.cases[0];
    if (!first) throw new Error("no reference cases");
    first.output = { ...(first.output as object), verses: 30 };
    const report = checkParity(resources, changed);
    expect(report.failures).toHaveLength(1);
    expect(report.failures[0]).toMatch(/^references case 0 /);
  });
});

describe("the specification", () => {
  it("is the version docs/engine.md and Swift's ReadingEngine state", () => {
    const stated = /^Specification version: \*\*(\d+)\*\*/m.exec(read("docs/engine.md"));
    const swift = /specificationVersion = (\d+)/.exec(
      read("Packages/ReadingEngine/Sources/ReadingEngine/ReadingEngine.swift"),
    );
    expect(Number(stated?.[1])).toBe(specificationVersion);
    expect(Number(swift?.[1])).toBe(specificationVersion);
  });
});

describe("numbers", () => {
  it("round halves away from zero, as Swift does", () => {
    expect([0.5, 1.5, 2.5, -0.5, -2.5, 2.4999, -2.4999].map(roundHalfAwayFromZero)).toEqual([
      1, 2, 3, -1, -3, 2, -2,
    ]);
  });

  it("read whole numbers as Swift's Int(String) does", () => {
    expect(["7", "+7", "-7", "007"].map(parseSwiftInt)).toEqual([7, 7, -7, 7]);
    expect(
      ["", "+", "7a", " 7", "7 ", "1.5", "１", "99999999999999999999"].map(parseSwiftInt),
    ).toEqual(Array(8).fill(undefined));
  });

  it("refuse a negative or fractional word count", () => {
    expect(() => workload(-1)).toThrow(RangeError);
    expect(() => workload(1.5)).toThrow(RangeError);
  });
});

describe("readings", () => {
  it("read back from their shortest writing as the same reading", () => {
    const { english } = resources;
    const reading = parseReading("GEN 1:1-31; PSA 117:1-2; JUD 1", english);
    expect(reading.passages.map((p) => [p.book, p.start, p.end])).toEqual([
      ["GEN", { chapter: 1, verse: 1 }, { chapter: 1, verse: 31 }],
      ["PSA", { chapter: 117, verse: 1 }, { chapter: 117, verse: 2 }],
      ["JUD", { chapter: 1, verse: 1 }, { chapter: 1, verse: 25 }],
    ]);
  });
});
