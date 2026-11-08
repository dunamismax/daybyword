-- Hand-written (PM.14). An imported catalog is a record: a plan version, its
-- facts and assignments, an import and its membership and scripture never
-- change or disappear once written. Only catalog_current moves, to serve
-- another import (a new release, or a rollback to an earlier one).
CREATE FUNCTION "catalog_refuse_change"() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
	RAISE EXCEPTION 'catalog rows are immutable: % on % refused', TG_OP, TG_TABLE_NAME
		USING ERRCODE = 'integrity_constraint_violation';
END;
$$;--> statement-breakpoint
CREATE TRIGGER "catalog_imports_immutable" BEFORE UPDATE OR DELETE ON "catalog_imports"
	FOR EACH ROW EXECUTE FUNCTION "catalog_refuse_change"();--> statement-breakpoint
CREATE TRIGGER "plans_immutable" BEFORE UPDATE OR DELETE ON "plans"
	FOR EACH ROW EXECUTE FUNCTION "catalog_refuse_change"();--> statement-breakpoint
CREATE TRIGGER "plan_facts_immutable" BEFORE UPDATE OR DELETE ON "plan_facts"
	FOR EACH ROW EXECUTE FUNCTION "catalog_refuse_change"();--> statement-breakpoint
CREATE TRIGGER "assignments_immutable" BEFORE UPDATE OR DELETE ON "assignments"
	FOR EACH ROW EXECUTE FUNCTION "catalog_refuse_change"();--> statement-breakpoint
CREATE TRIGGER "catalog_import_plans_immutable" BEFORE UPDATE OR DELETE ON "catalog_import_plans"
	FOR EACH ROW EXECUTE FUNCTION "catalog_refuse_change"();--> statement-breakpoint
CREATE TRIGGER "scripture_resources_immutable" BEFORE UPDATE OR DELETE ON "scripture_resources"
	FOR EACH ROW EXECUTE FUNCTION "catalog_refuse_change"();--> statement-breakpoint
CREATE TRIGGER "catalog_truncate_refused" BEFORE TRUNCATE ON "plans"
	FOR EACH STATEMENT EXECUTE FUNCTION "catalog_refuse_change"();
