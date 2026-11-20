// Importing a checked compiler export into PostgreSQL (BUILD.md PM.14,
// docs/catalog-format.md "The server catalog"). One transaction: either the
// whole catalog is written and served, or nothing changes. Importing the same
// export again writes nothing; importing an earlier one serves it again.
import { and, eq, sql } from "drizzle-orm";
import type { Database } from "../db/client.ts";
import { checkSchema } from "../db/migrations.ts";
import {
  assignments,
  catalogCurrent,
  catalogImportPlans,
  catalogImports,
  planFacts,
  plans,
  scriptureResources,
} from "../db/schema.ts";
import { checkExport, ExportError, planSha256, type CheckOptions } from "./export.ts";

export type ImportResult =
  | { status: "imported"; importId: number; plans: number; newPlanVersions: number }
  | { status: "already-current"; importId: number }
  | { status: "reactivated"; importId: number };

// Serializes imports across processes for the length of the transaction.
const importLock = 0x44_42_57_31; // "DBW1"

/** Checks `document` (checkExport) and imports it. */
export async function importCatalog(
  db: Database,
  document: unknown,
  options: CheckOptions = {},
): Promise<ImportResult> {
  const catalog = checkExport(document, options);
  await checkSchema(db);

  return db.transaction(async (tx) => {
    await tx.execute(sql`select pg_advisory_xact_lock(${importLock})`);
    const current = await tx.select().from(catalogCurrent);
    const existing = await tx
      .select({ id: catalogImports.id })
      .from(catalogImports)
      .where(eq(catalogImports.contentSha256, catalog.contentSha256));

    if (existing[0]) {
      const importId = existing[0].id;
      if (current[0]?.importId === importId) return { status: "already-current", importId };
      await serve(tx, importId);
      return { status: "reactivated", importId };
    }

    const [row] = await tx
      .insert(catalogImports)
      .values({
        contentSha256: catalog.contentSha256,
        formatVersion: catalog.formatVersion,
        schemaVersion: catalog.schemaVersion,
        buildMode: catalog.buildMode,
        planCount: catalog.plans.length,
      })
      .returning({ id: catalogImports.id });
    if (!row) throw new Error("the import row was not written");
    const importId = row.id;

    let newPlanVersions = 0;
    for (const [index, plan] of catalog.plans.entries()) {
      const digest = planSha256(plan);
      const prior = await tx
        .select({ contentSha256: plans.contentSha256 })
        .from(plans)
        .where(and(eq(plans.id, plan.id), eq(plans.version, plan.version)));
      if (prior[0]) {
        if (prior[0].contentSha256 !== digest) {
          throw new ExportError(
            `plan ${plan.id} version ${plan.version} differs from the version already imported; ` +
              "a published change raises the plan's version (docs/catalog-format.md)",
          );
        }
      } else {
        const { facts, assignments: readings, ...fields } = plan;
        await tx
          .insert(plans)
          .values({ ...fields, contentSha256: digest, firstImportId: importId });
        await tx.insert(planFacts).values({ planId: plan.id, planVersion: plan.version, ...facts });
        await tx
          .insert(assignments)
          .values(readings.map((a) => ({ planId: plan.id, planVersion: plan.version, ...a })));
        newPlanVersions += 1;
      }
      await tx.insert(catalogImportPlans).values({
        importId,
        planId: plan.id,
        planVersion: plan.version,
        position: index + 1,
      });
    }
    await tx
      .insert(scriptureResources)
      .values(catalog.scripture.map((r) => ({ importId, name: r.name, content: r.content })));
    await serve(tx, importId);
    return { status: "imported", importId, plans: catalog.plans.length, newPlanVersions };
  });
}

type Transaction = Parameters<Parameters<Database["transaction"]>[0]>[0];

async function serve(tx: Transaction, importId: number): Promise<void> {
  await tx
    .insert(catalogCurrent)
    .values({ singleton: 1, importId })
    .onConflictDoUpdate({
      target: catalogCurrent.singleton,
      set: { importId, activatedAt: sql`now()` },
    });
}
