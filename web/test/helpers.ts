import { readFileSync } from "node:fs";
import { contentSha256, type CatalogExport } from "../src/catalog/export.ts";

/** A fresh copy of tests/fixtures/catalog-export.json, written by the Swift compiler. */
export function fixtureExport(): CatalogExport {
  return JSON.parse(
    readFileSync(new URL("../../tests/fixtures/catalog-export.json", import.meta.url), "utf8"),
  ) as CatalogExport;
}

/** The fixture changed by `change`, with its checksum recomputed to match. */
export function changedExport(change: (catalog: CatalogExport) => void): CatalogExport {
  const catalog = fixtureExport();
  change(catalog);
  catalog.contentSha256 = contentSha256(catalog);
  return catalog;
}

export function plan(catalog: CatalogExport, id: string) {
  const found = catalog.plans.find((p) => p.id === id);
  if (!found) throw new Error(`no plan ${id} in the fixture`);
  return found;
}

export function assignment(catalog: CatalogExport, id: string, index: number) {
  const found = plan(catalog, id).assignments[index];
  if (!found) throw new Error(`plan ${id} has no assignment at ${index}`);
  return found;
}
