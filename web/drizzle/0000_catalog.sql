CREATE TABLE "assignments" (
	"plan_id" text NOT NULL,
	"plan_version" integer NOT NULL,
	"id" integer NOT NULL,
	"position" integer NOT NULL,
	"reading" text NOT NULL,
	"words" integer NOT NULL,
	CONSTRAINT "assignments_plan_id_plan_version_id_pk" PRIMARY KEY("plan_id","plan_version","id"),
	CONSTRAINT "assignments_position" UNIQUE("plan_id","plan_version","position"),
	CONSTRAINT "assignments_id" CHECK ("assignments"."id" >= 1),
	CONSTRAINT "assignments_position_from_1" CHECK ("assignments"."position" >= 1)
);
--> statement-breakpoint
CREATE TABLE "catalog_current" (
	"singleton" smallint PRIMARY KEY DEFAULT 1 NOT NULL,
	"import_id" integer NOT NULL,
	"activated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "catalog_current_singleton" CHECK ("catalog_current"."singleton" = 1)
);
--> statement-breakpoint
CREATE TABLE "catalog_import_plans" (
	"import_id" integer NOT NULL,
	"plan_id" text NOT NULL,
	"plan_version" integer NOT NULL,
	"position" integer NOT NULL,
	CONSTRAINT "catalog_import_plans_import_id_plan_id_pk" PRIMARY KEY("import_id","plan_id"),
	CONSTRAINT "catalog_import_plans_position" UNIQUE("import_id","position")
);
--> statement-breakpoint
CREATE TABLE "catalog_imports" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "catalog_imports_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"content_sha256" text NOT NULL,
	"format_version" integer NOT NULL,
	"schema_version" integer NOT NULL,
	"build_mode" text NOT NULL,
	"plan_count" integer NOT NULL,
	"imported_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "catalog_imports_contentSha256_unique" UNIQUE("content_sha256"),
	CONSTRAINT "catalog_imports_sha256" CHECK ("catalog_imports"."content_sha256" ~ '^[0-9a-f]{64}$'),
	CONSTRAINT "catalog_imports_build_mode" CHECK ("catalog_imports"."build_mode" in ('release', 'development'))
);
--> statement-breakpoint
CREATE TABLE "plan_facts" (
	"plan_id" text NOT NULL,
	"plan_version" integer NOT NULL,
	"verses" integer NOT NULL,
	"unique_verses" integer NOT NULL,
	"repeats" text NOT NULL,
	"omitted" text NOT NULL,
	"whole_chapters" integer NOT NULL,
	"partial_chapters" integer NOT NULL,
	"words_minimum" integer NOT NULL,
	"words_median" integer NOT NULL,
	"words_maximum" integer NOT NULL,
	CONSTRAINT "plan_facts_plan_id_plan_version_pk" PRIMARY KEY("plan_id","plan_version")
);
--> statement-breakpoint
CREATE TABLE "plans" (
	"id" text NOT NULL,
	"version" integer NOT NULL,
	"title" text NOT NULL,
	"creator" text NOT NULL,
	"summary" text NOT NULL,
	"suits" text NOT NULL,
	"schedule" text NOT NULL,
	"behaviors" text NOT NULL,
	"reading_days" smallint NOT NULL,
	"coverage" text NOT NULL,
	"canon" text NOT NULL,
	"books" text NOT NULL,
	"limitations" text NOT NULL,
	"instructions" text NOT NULL,
	"source" text NOT NULL,
	"rights" text NOT NULL,
	"rights_status" text NOT NULL,
	"review" text NOT NULL,
	"content_sha256" text NOT NULL,
	"first_import_id" integer NOT NULL,
	CONSTRAINT "plans_id_version_pk" PRIMARY KEY("id","version"),
	CONSTRAINT "plans_id" CHECK ("plans"."id" ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
	CONSTRAINT "plans_version" CHECK ("plans"."version" >= 1),
	CONSTRAINT "plans_reading_days" CHECK ("plans"."reading_days" between 1 and 7),
	CONSTRAINT "plans_schedule" CHECK ("plans"."schedule" in ('sequence', 'day-of-month')),
	CONSTRAINT "plans_coverage" CHECK ("plans"."coverage" in ('whole-bible', 'books', 'selection')),
	CONSTRAINT "plans_review" CHECK ("plans"."review" in ('checked', 'reviewed', 'expert')),
	CONSTRAINT "plans_rights_status" CHECK ("plans"."rights_status" in ('cleared', 'pending'))
);
--> statement-breakpoint
CREATE TABLE "scripture_resources" (
	"import_id" integer NOT NULL,
	"name" text NOT NULL,
	"content" text NOT NULL,
	CONSTRAINT "scripture_resources_import_id_name_pk" PRIMARY KEY("import_id","name")
);
--> statement-breakpoint
ALTER TABLE "assignments" ADD CONSTRAINT "assignments_plan_id_plan_version_plans_id_version_fk" FOREIGN KEY ("plan_id","plan_version") REFERENCES "public"."plans"("id","version") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "catalog_current" ADD CONSTRAINT "catalog_current_import_id_catalog_imports_id_fk" FOREIGN KEY ("import_id") REFERENCES "public"."catalog_imports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "catalog_import_plans" ADD CONSTRAINT "catalog_import_plans_import_id_catalog_imports_id_fk" FOREIGN KEY ("import_id") REFERENCES "public"."catalog_imports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "catalog_import_plans" ADD CONSTRAINT "catalog_import_plans_plan_id_plan_version_plans_id_version_fk" FOREIGN KEY ("plan_id","plan_version") REFERENCES "public"."plans"("id","version") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "plan_facts" ADD CONSTRAINT "plan_facts_plan_id_plan_version_plans_id_version_fk" FOREIGN KEY ("plan_id","plan_version") REFERENCES "public"."plans"("id","version") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "plans" ADD CONSTRAINT "plans_first_import_id_catalog_imports_id_fk" FOREIGN KEY ("first_import_id") REFERENCES "public"."catalog_imports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "scripture_resources" ADD CONSTRAINT "scripture_resources_import_id_catalog_imports_id_fk" FOREIGN KEY ("import_id") REFERENCES "public"."catalog_imports"("id") ON DELETE no action ON UPDATE no action;