// The compiler's catalog export, read and checked before anything is written
// to PostgreSQL (BUILD.md PM.14, docs/catalog-format.md "The export"). Pure:
// no database, no I/O. The Swift compiler writes the document
// (CatalogExport.swift); this module recomputes its content checksum exactly
// as the compiler does, so the import proves it holds the catalog the
// compiler checked.
import { createHash } from "node:crypto";

export const exportFormat = "daybyword-catalog-export";
export const exportFormatVersion = 1;
export const catalogSchemaVersion = 3;

export interface ExportFacts {
  verses: number;
  uniqueVerses: number;
  repeats: string;
  omitted: string;
  wholeChapters: number;
  partialChapters: number;
  wordsMinimum: number;
  wordsMedian: number;
  wordsMaximum: number;
}

export interface ExportAssignment {
  id: number;
  position: number;
  reading: string;
  words: number;
}

export interface ExportPlan {
  id: string;
  version: number;
  title: string;
  creator: string;
  summary: string;
  suits: string;
  schedule: string;
  behaviors: string;
  readingDays: number;
  coverage: string;
  canon: string;
  books: string;
  limitations: string;
  instructions: string;
  source: string;
  rights: string;
  rightsStatus: string;
  review: string;
  facts: ExportFacts;
  assignments: ExportAssignment[];
}

export interface ExportResource {
  name: string;
  content: string;
}

export interface CatalogExport {
  format: string;
  formatVersion: number;
  schemaVersion: number;
  buildMode: string;
  contentSha256: string;
  plans: ExportPlan[];
  scripture: ExportResource[];
}

/** Why an export cannot be imported. Nothing has been written when it is thrown. */
export class ExportError extends Error {
  override name = "ExportError";
}

export interface CheckOptions {
  /** Accept a development build (local work and tests only, never a deploy). */
  allowDevelopment?: boolean;
}

const reviewLevels = ["checked", "reviewed", "expert"];
const releaseReview = "reviewed";
const scriptureNames = ["books.json", "versification/english.tsv"];

// The plan's columns in the compiler's order (CatalogBuild.row), as the
// checksum writes them.
const planColumns: [string, keyof ExportPlan][] = [
  ["id", "id"],
  ["version", "version"],
  ["title", "title"],
  ["creator", "creator"],
  ["summary", "summary"],
  ["suits", "suits"],
  ["schedule", "schedule"],
  ["behaviors", "behaviors"],
  ["reading_days", "readingDays"],
  ["coverage", "coverage"],
  ["canon", "canon"],
  ["books", "books"],
  ["limitations", "limitations"],
  ["instructions", "instructions"],
  ["source", "source"],
  ["rights", "rights"],
  ["review", "review"],
];
const factColumns: [string, keyof ExportFacts][] = [
  ["verses", "verses"],
  ["unique_verses", "uniqueVerses"],
  ["repeats", "repeats"],
  ["omitted", "omitted"],
  ["whole_chapters", "wholeChapters"],
  ["partial_chapters", "partialChapters"],
  ["words_minimum", "wordsMinimum"],
  ["words_median", "wordsMedian"],
  ["words_maximum", "wordsMaximum"],
];

/** The bytes the compiler hashes for one plan: its columns, facts and assignments. */
function planBlock(plan: ExportPlan): string {
  let text = "";
  for (const [column, key] of planColumns) text += `${column}\t${String(plan[key])}\n`;
  for (const [column, key] of factColumns) text += `${column}\t${String(plan.facts[key])}\n`;
  for (const a of plan.assignments) text += `${a.id}\t${a.reading}\t${a.words}\n`;
  return text;
}

const sha256 = (text: string): string => createHash("sha256").update(text, "utf8").digest("hex");

/** A SHA-256 of one plan version's content, which never changes for that version. */
export const planSha256 = (plan: ExportPlan): string => sha256(planBlock(plan));

/** The catalog's content checksum, computed as CatalogBuild.metadata does. */
export function contentSha256(catalog: Pick<CatalogExport, "plans" | "scripture">): string {
  const hash = createHash("sha256");
  for (const r of catalog.scripture) hash.update(`${r.name}\n${r.content}\n`, "utf8");
  for (const plan of catalog.plans) hash.update(planBlock(plan), "utf8");
  return hash.digest("hex");
}

// Shape checks for untrusted JSON.
type Shape = Record<string, "string" | "number">;
const planShape: Shape = {
  id: "string",
  version: "number",
  title: "string",
  creator: "string",
  summary: "string",
  suits: "string",
  schedule: "string",
  behaviors: "string",
  readingDays: "number",
  coverage: "string",
  canon: "string",
  books: "string",
  limitations: "string",
  instructions: "string",
  source: "string",
  rights: "string",
  rightsStatus: "string",
  review: "string",
};
const factsShape: Shape = Object.fromEntries(
  factColumns.map(([, key]) => [key, key === "repeats" || key === "omitted" ? "string" : "number"]),
);
const assignmentShape: Shape = {
  id: "number",
  position: "number",
  reading: "string",
  words: "number",
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function checkShape(value: unknown, shape: Shape, where: string): void {
  if (!isRecord(value)) throw new ExportError(`${where} is not an object`);
  for (const [key, kind] of Object.entries(shape)) {
    const field = value[key];
    if (typeof field !== kind) throw new ExportError(`${where}.${key} is not a ${kind}`);
    if (kind === "number" && !Number.isSafeInteger(field)) {
      throw new ExportError(`${where}.${key} is not a whole number`);
    }
  }
}

/**
 * Reads an export document and checks everything the server relies on before
 * writing it: the format and schema, the build mode, the checksum, each
 * plan's rights and review for a release, its coverage claim, and the order
 * of its assignments. Returns the document, typed.
 */
export function checkExport(document: unknown, options: CheckOptions = {}): CatalogExport {
  if (!isRecord(document)) throw new ExportError("the export is not a JSON object");
  if (document["format"] !== exportFormat) {
    throw new ExportError(`the export's format is not ${exportFormat}`);
  }
  if (document["formatVersion"] !== exportFormatVersion) {
    throw new ExportError(
      `the export is format ${String(document["formatVersion"])}; this build reads format ${exportFormatVersion}`,
    );
  }
  if (document["schemaVersion"] !== catalogSchemaVersion) {
    throw new ExportError(
      `the export is catalog schema ${String(document["schemaVersion"])}; this build reads schema ${catalogSchemaVersion}`,
    );
  }
  const mode = document["buildMode"];
  if (mode !== "release" && !(mode === "development" && options.allowDevelopment)) {
    throw new ExportError(
      `the export is a ${String(mode)} build; only a release build is imported (RELEASE=1 make catalog)`,
    );
  }
  const release = mode === "release";
  if (typeof document["contentSha256"] !== "string") {
    throw new ExportError("the export has no content checksum");
  }
  const rawPlans = document["plans"];
  const rawScripture = document["scripture"];
  if (!Array.isArray(rawPlans)) throw new ExportError("the export's plans are not a list");
  if (!Array.isArray(rawScripture)) throw new ExportError("the export's scripture is not a list");

  rawScripture.forEach((r, i) =>
    checkShape(r, { name: "string", content: "string" }, `scripture[${i}]`),
  );
  const scripture = rawScripture as ExportResource[];
  const names = scripture.map((r) => r.name);
  if (names.join("\n") !== scriptureNames.join("\n")) {
    throw new ExportError(
      `the export's scripture is ${names.join(", ")}, not ${scriptureNames.join(", ")}`,
    );
  }

  const seen = new Set<string>();
  rawPlans.forEach((raw, i) => {
    checkShape(raw, planShape, `plans[${i}]`);
    const plan = raw as ExportPlan;
    const where = `plan ${plan.id} version ${plan.version}`;
    checkShape(plan.facts, factsShape, `${where}: facts`);
    if (!Array.isArray(plan.assignments))
      throw new ExportError(`${where}: assignments are not a list`);
    plan.assignments.forEach((a, j) =>
      checkShape(a, assignmentShape, `${where}: assignments[${j}]`),
    );

    if (seen.has(plan.id)) throw new ExportError(`${where}: the plan appears twice`);
    seen.add(plan.id);
    if (plan.version < 1) throw new ExportError(`${where}: a version is a whole number from 1`);

    if (plan.rightsStatus !== "cleared" && !(plan.rightsStatus === "pending" && !release)) {
      throw new ExportError(
        `${where}: rights ${plan.rights} is ${plan.rightsStatus}, so it cannot be served in a ${String(mode)} build`,
      );
    }
    const level = reviewLevels.indexOf(plan.review);
    if (level < 0) throw new ExportError(`${where}: review ${plan.review} is not a review level`);
    if (release && level < reviewLevels.indexOf(releaseReview)) {
      throw new ExportError(
        `${where}: review is ${plan.review}, below ${releaseReview}, so it is not released`,
      );
    }
    if (
      (plan.coverage === "whole-bible" || plan.coverage === "books") &&
      plan.facts.omitted !== ""
    ) {
      throw new ExportError(
        `${where}: claims ${plan.coverage} coverage but omits ${plan.facts.omitted.split("; ")[0]}`,
      );
    }
    const { wordsMinimum, wordsMedian, wordsMaximum } = plan.facts;
    if (!(wordsMinimum <= wordsMedian && wordsMedian <= wordsMaximum)) {
      throw new ExportError(`${where}: its workload is out of order`);
    }
    if (plan.assignments.length === 0) throw new ExportError(`${where}: has no assignments`);
    const ids = new Set<number>();
    plan.assignments.forEach((a, j) => {
      if (a.position !== j + 1) {
        throw new ExportError(
          `${where}: assignment ${a.id} is at position ${a.position}, not ${j + 1}`,
        );
      }
      if (a.id < 1 || ids.has(a.id))
        throw new ExportError(`${where}: assignment id ${a.id} is not unique`);
      ids.add(a.id);
    });
  });

  const catalog = document as unknown as CatalogExport;
  const computed = contentSha256(catalog);
  if (computed !== catalog.contentSha256) {
    throw new ExportError(
      `the export's content does not match its checksum (${catalog.contentSha256.slice(0, 12)}…, computed ${computed.slice(0, 12)}…)`,
    );
  }
  return catalog;
}
