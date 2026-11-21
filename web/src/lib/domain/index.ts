// Day by Word's reading logic for the web: the TypeScript runtime of
// docs/engine.md, held to the same shared fixtures as Swift's ReadingEngine
// (docs/decisions.md E33, tests/fixtures/). Pure: no DOM, no Node APIs, no
// database, no Svelte; the server and the browser both import it, and the
// lint refuses anything else here. Callers load the scripture resources
// (books.json, the versification, the word counts) and pass their text in.

/** The version of docs/engine.md this module implements; Swift's ReadingEngine states the same. */
export const specificationVersion = 0;

export * from "./ids.ts";
export * from "./numbers.ts";
export * from "./civil-date.ts";
export * from "./wall-time.ts";
export * from "./event-id.ts";
export * from "./registry.ts";
export * from "./versification.ts";
export * from "./passage.ts";
export * from "./reference-format.ts";
export * from "./reference-formatter.ts";
export * from "./verse-set.ts";
export * from "./word-counts.ts";
export * from "./workload.ts";
export * from "./plan.ts";
export * from "./journal.ts";
