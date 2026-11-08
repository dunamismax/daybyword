import { defineConfig } from "vitest/config";

// test/db/ needs a real PostgreSQL and runs only through make test-db.
const database = process.env["DBW_TEST_DB"] === "1";

export default defineConfig({
  test: {
    include: database ? ["test/db/**/*.test.ts"] : ["test/**/*.test.ts"],
    exclude: database ? [] : ["test/db/**"],
    environment: "node",
    fileParallelism: !database,
    testTimeout: database ? 30_000 : 5_000,
  },
});
