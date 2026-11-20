// The server's PostgreSQL schema (BUILD.md PM.14, docs/catalog-format.md
// "The server catalog"). Server-only: nothing under src/pages or any browser
// or native bundle imports this module's client. At 1.0 the database holds
// the public catalog alone; no reader data (D10, D39).
//
// Plans are immutable by (id, version). Each import of a compiler export is a
// row in catalog_imports; catalog_import_plans says which plan versions it
// holds, and catalog_current points at the import being served.
import { sql } from "drizzle-orm";
import {
  check,
  foreignKey,
  integer,
  pgTable,
  primaryKey,
  smallint,
  text,
  timestamp,
  unique,
} from "drizzle-orm/pg-core";

export const catalogImports = pgTable(
  "catalog_imports",
  {
    id: integer().primaryKey().generatedAlwaysAsIdentity(),
    contentSha256: text().notNull().unique(),
    formatVersion: integer().notNull(),
    schemaVersion: integer().notNull(),
    buildMode: text().notNull(),
    planCount: integer().notNull(),
    importedAt: timestamp({ withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    check("catalog_imports_sha256", sql`${t.contentSha256} ~ '^[0-9a-f]{64}$'`),
    check("catalog_imports_build_mode", sql`${t.buildMode} in ('release', 'development')`),
  ],
);

export const plans = pgTable(
  "plans",
  {
    id: text().notNull(),
    version: integer().notNull(),
    title: text().notNull(),
    creator: text().notNull(),
    summary: text().notNull(),
    suits: text().notNull(),
    schedule: text().notNull(),
    behaviors: text().notNull(),
    readingDays: smallint().notNull(),
    coverage: text().notNull(),
    canon: text().notNull(),
    books: text().notNull(),
    limitations: text().notNull(),
    instructions: text().notNull(),
    source: text().notNull(),
    rights: text().notNull(),
    rightsStatus: text().notNull(),
    review: text().notNull(),
    // A SHA-256 of this version's fields, facts and assignments, so a second
    // import can prove it is the same version and not a silent change.
    contentSha256: text().notNull(),
    firstImportId: integer()
      .notNull()
      .references(() => catalogImports.id),
  },
  (t) => [
    primaryKey({ columns: [t.id, t.version] }),
    check("plans_id", sql`${t.id} ~ '^[a-z0-9]+(-[a-z0-9]+)*$'`),
    check("plans_version", sql`${t.version} >= 1`),
    check("plans_reading_days", sql`${t.readingDays} between 1 and 7`),
    check("plans_schedule", sql`${t.schedule} in ('sequence', 'day-of-month')`),
    check("plans_coverage", sql`${t.coverage} in ('whole-bible', 'books', 'selection')`),
    check("plans_review", sql`${t.review} in ('checked', 'reviewed', 'expert')`),
    check("plans_rights_status", sql`${t.rightsStatus} in ('cleared', 'pending')`),
  ],
);

export const planFacts = pgTable(
  "plan_facts",
  {
    planId: text().notNull(),
    planVersion: integer().notNull(),
    verses: integer().notNull(),
    uniqueVerses: integer().notNull(),
    repeats: text().notNull(),
    omitted: text().notNull(),
    wholeChapters: integer().notNull(),
    partialChapters: integer().notNull(),
    wordsMinimum: integer().notNull(),
    wordsMedian: integer().notNull(),
    wordsMaximum: integer().notNull(),
  },
  (t) => [
    primaryKey({ columns: [t.planId, t.planVersion] }),
    foreignKey({ columns: [t.planId, t.planVersion], foreignColumns: [plans.id, plans.version] }),
  ],
);

export const assignments = pgTable(
  "assignments",
  {
    planId: text().notNull(),
    planVersion: integer().notNull(),
    id: integer().notNull(),
    position: integer().notNull(),
    reading: text().notNull(),
    words: integer().notNull(),
  },
  (t) => [
    primaryKey({ columns: [t.planId, t.planVersion, t.id] }),
    unique("assignments_position").on(t.planId, t.planVersion, t.position),
    foreignKey({ columns: [t.planId, t.planVersion], foreignColumns: [plans.id, plans.version] }),
    check("assignments_id", sql`${t.id} >= 1`),
    check("assignments_position_from_1", sql`${t.position} >= 1`),
  ],
);

export const catalogImportPlans = pgTable(
  "catalog_import_plans",
  {
    importId: integer()
      .notNull()
      .references(() => catalogImports.id),
    planId: text().notNull(),
    planVersion: integer().notNull(),
    // The plan's place in the compiler's order, which the checksum follows.
    position: integer().notNull(),
  },
  (t) => [
    primaryKey({ columns: [t.importId, t.planId] }),
    unique("catalog_import_plans_position").on(t.importId, t.position),
    foreignKey({ columns: [t.planId, t.planVersion], foreignColumns: [plans.id, plans.version] }),
  ],
);

export const scriptureResources = pgTable(
  "scripture_resources",
  {
    importId: integer()
      .notNull()
      .references(() => catalogImports.id),
    name: text().notNull(),
    content: text().notNull(),
  },
  (t) => [primaryKey({ columns: [t.importId, t.name] })],
);

// One row: the import being served.
export const catalogCurrent = pgTable(
  "catalog_current",
  {
    singleton: smallint().primaryKey().default(1),
    importId: integer()
      .notNull()
      .references(() => catalogImports.id),
    activatedAt: timestamp({ withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [check("catalog_current_singleton", sql`${t.singleton} = 1`)],
);
