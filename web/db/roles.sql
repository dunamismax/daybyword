-- The database's roles in every test and throwaway cluster (make test-db,
-- scripts/with-catalog.sh, deploy/bin/restore-check.sh): the model the
-- server's PostgreSQL uses (docs/deploy.md, the host's web platform contract),
-- where bin/provision-app-database daybyword --web-access read-only created
-- them. Run by the superuser, connected to this project's database. Safe to
-- run again. Passwords exist only on the server, never here.
--
--   daybyword_owner      owns the database, schema app and every object;
--                        cannot log in.
--   daybyword_migration  the deploy's migration and catalog-import step:
--                        becomes daybyword_owner only with SET ROLE.
--   daybyword_web        the web server: reads the catalog, and nothing else.
DO $$
BEGIN
	IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'daybyword_owner') THEN
		CREATE ROLE daybyword_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
	END IF;
	IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'daybyword_migration') THEN
		CREATE ROLE daybyword_migration LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
	END IF;
	IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'daybyword_web') THEN
		CREATE ROLE daybyword_web LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
	END IF;
	EXECUTE format('ALTER DATABASE %I OWNER TO daybyword_owner', current_database());
	EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
	EXECUTE format('GRANT CONNECT ON DATABASE %I TO daybyword_migration, daybyword_web', current_database());
	EXECUTE format('ALTER ROLE daybyword_migration IN DATABASE %I SET search_path = app, pg_catalog', current_database());
	EXECUTE format('ALTER ROLE daybyword_web IN DATABASE %I SET search_path = app, pg_catalog', current_database());
	EXECUTE format('ALTER ROLE daybyword_web IN DATABASE %I SET default_transaction_read_only = on', current_database());
	EXECUTE format('ALTER ROLE daybyword_web IN DATABASE %I SET statement_timeout = %L', current_database(), '30s');
END
$$;
GRANT daybyword_owner TO daybyword_migration WITH INHERIT FALSE, SET TRUE;

REVOKE ALL ON SCHEMA public FROM PUBLIC;
ALTER SCHEMA public OWNER TO daybyword_owner;
-- As on the server: nothing the owner creates is PUBLIC's. Migration 0002
-- grants the web role what it reads.
ALTER DEFAULT PRIVILEGES FOR ROLE daybyword_owner REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE daybyword_owner REVOKE USAGE ON TYPES FROM PUBLIC;
