// drizzle-kit generates the reviewed SQL migrations in drizzle/ from
// src/db/schema.ts (`make db-generate`). Migrations are applied by
// scripts/db-migrate.ts, never by the web server on a request.
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  dialect: "postgresql",
  schema: "./src/db/schema.ts",
  out: process.env["DBW_DRIZZLE_OUT"] ?? "./drizzle",
  casing: "snake_case",
  strict: true,
  verbose: false,
});
