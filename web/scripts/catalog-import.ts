// The one-shot catalog import job:
//
//   node scripts/catalog-import.ts [--check] [--allow-development] EXPORT.json
//
// --check reads and checks the export without a database. Otherwise it
// imports it into the database in DATABASE_URL (or the PG* variables)
// in one transaction, as the owner (migration.env's DB_OWNER_ROLE).
// Development builds are refused unless --allow-development is given, which
// is for local work only.
import { readFileSync } from "node:fs";
import { checkExport } from "#lib/server/catalog/export.ts";
import { importCatalog } from "#lib/server/catalog/import.ts";
import { createPool, database } from "#lib/server/db/client.ts";

const args = process.argv.slice(2);
const checkOnly = args.includes("--check");
const allowDevelopment = args.includes("--allow-development");
const files = args.filter((a) => !a.startsWith("--"));
const unknown = args.filter(
  (a) => a.startsWith("--") && a !== "--check" && a !== "--allow-development",
);

if (files.length !== 1 || unknown.length > 0) {
  console.error("usage: catalog-import [--check] [--allow-development] EXPORT.json");
  process.exit(2);
}

try {
  const document: unknown = JSON.parse(readFileSync(files[0] ?? "", "utf8"));
  if (checkOnly) {
    const catalog = checkExport(document, { allowDevelopment });
    console.log(
      `catalog-import: ${files[0]} is a valid ${catalog.buildMode} export of ${catalog.plans.length} plan(s), ${catalog.contentSha256.slice(0, 12)}…`,
    );
  } else {
    const pool = createPool();
    try {
      const result = await importCatalog(database(pool), document, { allowDevelopment });
      console.log(`catalog-import: ${result.status} (import ${result.importId})`);
    } finally {
      await pool.end();
    }
  }
} catch (error) {
  console.error(`catalog-import: ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 1;
}
