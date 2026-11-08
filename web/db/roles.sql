-- The database's two roles (BUILD.md PM.14, docs/deploy.md). Run once by the
-- PostgreSQL superuser, connected to this project's own database, when it
-- is provisioned (PM.18, P7.3); passwords are set separately from the
-- root-owned env file and never committed. Safe to run again.
--
--   daybyword_migrate  owns the schema: applies migrations and imports the
--                      catalog, from the one-shot jobs, never the web server.
--   daybyword_app      the web server: reads the catalog, and nothing else.
DO $$
BEGIN
	IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'daybyword_migrate') THEN
		CREATE ROLE daybyword_migrate LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;
	END IF;
	IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'daybyword_app') THEN
		CREATE ROLE daybyword_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;
	END IF;
	EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
	EXECUTE format('GRANT CONNECT, CREATE, TEMPORARY ON DATABASE %I TO daybyword_migrate', current_database());
	EXECUTE format('GRANT CONNECT ON DATABASE %I TO daybyword_app', current_database());
END
$$;

REVOKE ALL ON SCHEMA public FROM PUBLIC;
ALTER SCHEMA public OWNER TO daybyword_migrate;
GRANT USAGE ON SCHEMA public TO daybyword_app;

-- Whatever the migrator creates, the web server may read and only read.
ALTER DEFAULT PRIVILEGES FOR ROLE daybyword_migrate IN SCHEMA public
	GRANT SELECT ON TABLES TO daybyword_app;
ALTER DEFAULT PRIVILEGES FOR ROLE daybyword_migrate IN SCHEMA public
	REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
