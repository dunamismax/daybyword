-- Hand-written and reviewed (the host's web platform contract, 2026-11-21;
-- docs/decisions.md E46). The server's PostgreSQL keeps every application
-- table in schema app, and its roles' search_path is app, pg_catalog. 0000 and
-- 0001 created the catalog in public; this moves the tables (their indexes,
-- constraints, identity sequences and triggers go with them) and the trigger
-- function to app, and gives the read-only web role what it reads. Nothing
-- is copied or dropped. The release that was serving read public through the
-- container's own database, never this one, so no serving release reads the
-- old shape.
CREATE SCHEMA IF NOT EXISTS "app";--> statement-breakpoint
ALTER TABLE "public"."catalog_imports" SET SCHEMA "app";--> statement-breakpoint
ALTER TABLE "public"."plans" SET SCHEMA "app";--> statement-breakpoint
ALTER TABLE "public"."plan_facts" SET SCHEMA "app";--> statement-breakpoint
ALTER TABLE "public"."assignments" SET SCHEMA "app";--> statement-breakpoint
ALTER TABLE "public"."catalog_import_plans" SET SCHEMA "app";--> statement-breakpoint
ALTER TABLE "public"."scripture_resources" SET SCHEMA "app";--> statement-breakpoint
ALTER TABLE "public"."catalog_current" SET SCHEMA "app";--> statement-breakpoint
ALTER FUNCTION "public"."catalog_refuse_change"() SET SCHEMA "app";--> statement-breakpoint
GRANT USAGE ON SCHEMA "app" TO "daybyword_web";--> statement-breakpoint
GRANT SELECT ON ALL TABLES IN SCHEMA "app" TO "daybyword_web";--> statement-breakpoint
ALTER DEFAULT PRIVILEGES IN SCHEMA "app" GRANT SELECT ON TABLES TO "daybyword_web";
