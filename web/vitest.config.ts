import { defineConfig } from "vitest/config";

// test/db/ needs a real PostgreSQL and runs only through make test-db;
// test/build/ needs the production build and runs only through make smoke-web.
const database = process.env["DBW_TEST_DB"] === "1";
const build = process.env["DBW_TEST_BUILD"] === "1";

export default defineConfig({
  test: {
    include: database
      ? ["test/db/**/*.test.ts"]
      : build
        ? ["test/build/**/*.test.ts"]
        : ["test/**/*.test.ts"],
    exclude: database || build ? [] : ["test/db/**", "test/build/**"],
    environment: "node",
    fileParallelism: !database,
    testTimeout: database || build ? 30_000 : 5_000,
    hookTimeout: 30_000,
  },
});
