// The catalog the web serves, read from PostgreSQL as the read-only web
// role (docs/catalog-format.md, "The server catalog"): the plans of the
// import `catalog_current` names, with their facts and assignments, the
// goals they are grouped by, and the scripture it was compiled with. Server-only. Read once per import and
// kept in memory; each request asks only which import is current. Without
// DATABASE_URL (local work with no database) there is no catalog.
import pg from "pg";
import {
  BookRegistry,
  goals as goalOrder,
  isGoal,
  isPlanID,
  parseReading,
  Versification,
  type Behavior,
  type BookID,
  type Goal,
  type PlanID,
  type PlanVersion,
  type ScheduleKind,
} from "#lib/domain/index.ts";

export type CoverageClaim = "whole-bible" | "books" | "selection";
export type ReviewLevel = "checked" | "reviewed" | "expert";

/** What the compiler computed from a plan's schedule (docs/catalog-format.md, "What the compiler adds"). */
export interface CatalogFacts {
  readonly verses: number;
  readonly uniqueVerses: number;
  /** Passages in plan-file writing, joined by "; "; empty when there are none. */
  readonly repeats: string;
  readonly omitted: string;
  readonly wholeChapters: number;
  readonly partialChapters: number;
  readonly wordsMinimum: number;
  readonly wordsMedian: number;
  readonly wordsMaximum: number;
}

/** One plan version as the catalog holds it. */
export interface CatalogPlan {
  readonly id: PlanID;
  readonly version: number;
  readonly title: string;
  readonly creator: string;
  readonly summary: string;
  readonly suits: string;
  readonly coverage: CoverageClaim;
  readonly canon: string;
  readonly books: readonly BookID[];
  readonly limitations: string;
  readonly instructions: string;
  readonly source: string;
  /** Its entry in catalog/SOURCES.md. */
  readonly rights: string;
  readonly review: ReviewLevel;
  readonly facts: CatalogFacts;
  /** The plan as the reading rules take it. */
  readonly plan: PlanVersion;
}

/** A goal and its plans, in the order the plan list shows them (catalog/goals.json). */
export interface CatalogGoal {
  readonly goal: Goal;
  readonly plans: readonly PlanID[];
}

export interface ServedCatalog {
  readonly importId: number;
  /** In the compiler's order. */
  readonly plans: readonly CatalogPlan[];
  /** In the engine's order; an import from before goals has none. */
  readonly goals: readonly CatalogGoal[];
  readonly registry: BookRegistry;
  readonly versification: Versification;
  /** What the book registry's names and orders were checked against (books.json's sources). */
  readonly bookSources: readonly BookSource[];
}

/** A work the book registry cites (catalog/scripture/books.json). */
export interface BookSource {
  readonly title: string;
  readonly publisher: string;
  readonly url: string;
  readonly usedFor: string;
}

let pool: pg.Pool | undefined;
let cached: ServedCatalog | undefined;

interface PlanRow {
  id: string;
  version: number;
  title: string;
  creator: string;
  summary: string;
  suits: string;
  schedule: string;
  behaviors: string;
  reading_days: number;
  coverage: string;
  canon: string;
  books: string;
  limitations: string;
  instructions: string;
  source: string;
  rights: string;
  review: string;
  verses: number;
  unique_verses: number;
  repeats: string;
  omitted: string;
  whole_chapters: number;
  partial_chapters: number;
  words_minimum: number;
  words_median: number;
  words_maximum: number;
}

interface AssignmentRow {
  plan_id: string;
  id: number;
  reading: string;
  words: number;
}

async function read(client: pg.Pool, importId: number): Promise<ServedCatalog> {
  const [resources, plans, assignments, goalRows] = await Promise.all([
    client.query<{ name: string; content: string }>(
      "select name, content from app.scripture_resources where import_id = $1",
      [importId],
    ),
    client.query<PlanRow>(
      `select p.*, f.verses, f.unique_verses, f.repeats, f.omitted, f.whole_chapters,
              f.partial_chapters, f.words_minimum, f.words_median, f.words_maximum
         from app.catalog_import_plans i
         join app.plans p on p.id = i.plan_id and p.version = i.plan_version
         join app.plan_facts f on f.plan_id = p.id and f.plan_version = p.version
        where i.import_id = $1
        order by i.position`,
      [importId],
    ),
    client.query<AssignmentRow>(
      `select a.plan_id, a.id, a.reading, a.words
         from app.catalog_import_plans i
         join app.assignments a on a.plan_id = i.plan_id and a.plan_version = i.plan_version
        where i.import_id = $1
        order by a.plan_id, a.position`,
      [importId],
    ),
    client.query<{ goal: string; plan_id: string }>(
      "select goal, plan_id from app.catalog_goals where import_id = $1 order by goal, position",
      [importId],
    ),
  ]);
  const resource = (name: string) => {
    const found = resources.rows.find((row) => row.name === name);
    if (!found) throw new Error(`the catalog has no ${name}`);
    return found.content;
  };
  const registry = new BookRegistry(resource("books.json"));
  const cited = (JSON.parse(resource("books.json")) as { sources?: BookSource[] }).sources ?? [];
  const bookSources = cited.map(({ title, publisher, url, usedFor }) => ({
    title,
    publisher,
    url,
    usedFor,
  }));
  const versification = new Versification("english", resource("versification/english.tsv"));

  const goals: CatalogGoal[] = goalOrder.flatMap((goal) => {
    const own = goalRows.rows.filter((row) => row.goal === goal).map((row) => row.plan_id);
    return own.length === 0 ? [] : [{ goal, plans: own.filter(isPlanID) }];
  });
  const stray = goalRows.rows.find((row) => !isGoal(row.goal));
  if (stray) throw new Error(`the catalog has a goal named ${stray.goal}`);

  return {
    importId,
    registry,
    versification,
    bookSources,
    goals,
    plans: plans.rows.map((row) => {
      if (!isPlanID(row.id)) throw new Error(`the catalog has a plan with the id ${row.id}`);
      const own = assignments.rows.filter((assignment) => assignment.plan_id === row.id);
      return {
        id: row.id,
        version: row.version,
        title: row.title,
        creator: row.creator,
        summary: row.summary,
        suits: row.suits,
        coverage: row.coverage as CoverageClaim,
        canon: row.canon,
        books: row.books.split(", ") as BookID[],
        limitations: row.limitations,
        instructions: row.instructions,
        source: row.source,
        rights: row.rights,
        review: row.review as ReviewLevel,
        facts: {
          verses: row.verses,
          uniqueVerses: row.unique_verses,
          repeats: row.repeats,
          omitted: row.omitted,
          wholeChapters: row.whole_chapters,
          partialChapters: row.partial_chapters,
          wordsMinimum: row.words_minimum,
          wordsMedian: row.words_median,
          wordsMaximum: row.words_maximum,
        },
        plan: {
          id: row.id,
          version: row.version,
          schedule: row.schedule as ScheduleKind,
          behaviors: row.behaviors.split(", ") as Behavior[],
          readingDays: row.reading_days,
          assignments: own.map((assignment) => ({
            id: assignment.id,
            reading: parseReading(assignment.reading, versification),
          })),
          words: new Map(own.map((assignment) => [assignment.id, assignment.words])),
        },
      };
    }),
  };
}

/**
 * The catalog being served, or undefined when there is no database or no
 * import is current. Throws when the database cannot be reached.
 */
export async function servedCatalog(
  url: string | undefined = process.env["DATABASE_URL"],
): Promise<ServedCatalog | undefined> {
  if (url === undefined || url === "") return undefined;
  pool ??= new pg.Pool({
    connectionString: url,
    max: 4,
    connectionTimeoutMillis: 2_000,
    idleTimeoutMillis: 30_000,
  });
  const current = await pool.query<{ import_id: number }>(
    "select import_id from app.catalog_current limit 1",
  );
  const importId = current.rows[0]?.import_id;
  if (importId === undefined) return undefined;
  if (cached?.importId !== importId) cached = await read(pool, importId);
  return cached;
}

/** Closes the pool and forgets the catalog, for tests and shutdown. */
export async function closeCatalog(): Promise<void> {
  await pool?.end();
  pool = undefined;
  cached = undefined;
}
