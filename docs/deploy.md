# Astro/PostgreSQL deployment plan

**D41, planned only (2026-11-02).** Nothing was provisioned or deployed
during this review. PM.18 builds/rehearses scripts; P7 verifies the host and
performs first production deployment. Do not treat planned paths as live
evidence. No server SQLite, Litestream or mandatory Python service.

## Isolation and layout

| Resource | Planned convention; inspect before use |
|---|---|
| Host | ubuntu-vm under D34; existing shared Caddy |
| Release root | /srv/www/daybyword.com/releases/<commit>, current pointer |
| Persistent resources | shared/env (root-owned 0600), shared/storage, shared/backups |
| Source files | deploy/compose.yaml, deploy/Dockerfile, deploy/caddy/daybyword.com |
| Compose project | daybyword; web, postgres, one-shot migration/catalog import |
| Web listener | container 0.0.0.0:4321, published only at 127.0.0.1:4316 if free |
| Postgres | private Docker network port 5432; no production host port |
| DB/role | daybyword / daybyword_app; separate migration/import credential |
| Volume | explicit daybyword_postgres_data; stable across release directories |
| Host Caddy site | /etc/caddy/sites/daybyword.com after verifying include convention |
| Health | /up, no-store, ready only with compatible DB/catalog |
| Shared deploy lock | discover and record the existing host path; never invent a new parallel lock |

Record other sites' responses before/after every server change. Archive
/etc/caddy before touching it. Add only this site's configuration; never
edit another site's file, DB, service, user or backup entry. No second
Caddy, Coolify or Dokploy. Missing shared DNS modules need coordinated
host work, not unilateral proxy replacement. No live host access occurred
for this documentation revision.

## Application and secrets

Use @astrojs/node standalone. This app needs runtime API/Actions/database
work; static public routes may prerender. A pure static content deployment
can be served directly by Caddy, but it cannot replace runtime APIs.
Build a pinned non-root Node image from a clean origin/main archive, copy
the built client/server assets and required migrations/catalog resources,
and test the actual image. No checkout as web root or runtime bind mount.

Document runtime HOST/PORT, public origin, DATABASE_URL, separate migrator
credentials, DBW_COMMIT and catalog digest/schema. Existing Swift DBW_HOST,
DBW_PORT, DBW_PUBLIC_DIR and DBW_CATALOG need explicit mapping/removal.
Only public config may use client-exposed environment variables. No secrets
in build args, layers, logs, JS/native bundles or repository. Framework/
build telemetry is disabled. No auth/model/billing secret is needed at 1.0.

Postgres readiness must precede one-shot migration/import and candidate
readiness. Use bounded connection pools, restart/resource/log limits and
graceful shutdown. Persist only project data; never down -v during release.

## Proxy/TLS

Preserve Caddy and Cloudflare. When DNS is proxied use Full (strict), with
a valid origin certificate; never Flexible. Prefer the Cloudflare DNS
challenge with the host's caddy-dns/cloudflare module and a zone-scoped
token in protected host environment. Inspect modules/certificates first;
the owner handles account settings and shared binary coordination.
Verify apex HTTPS, permanent www redirect retaining path/query, renewal,
headers and actual Astro CSP/island behavior. No remote resources.
Do not cache private APIs or personal HTML. Proxy/app logs omit bodies,
cookies/tokens, query strings and concrete plan paths; retain route pattern,
method, status and duration only.

## Release and rollback

1. Run make check-full and push main. Under the existing shared lock,
   resolve clean origin/main and record active image/config/schema/catalog.
2. Back up the project database. Apply reviewed generated Drizzle SQL once
   with migration credentials; import release-cleared catalog atomically
   and idempotently. No production schema push.
3. Boot the candidate on a verified spare loopback port. Verify /up,
   routes/assets/SSR, any Actions/islands, CSP and matching catalog digest.
4. Activate only this project's web container/release. Run check-live over
   public apex/www and compare other sites. Retain previous image/config.
5. On failure roll back compatible code/config. Use expand/contract SQL;
   never assume code rollback reverses destructive SQL, delete volumes or
   blindly restore over newer reader records. Rehearse DB recovery apart.

Retain the in-development/noindex/robots block until P18.5.

## Backups and jobs

Start nightly pg_dump with the first Postgres deployment, even while the
DB holds only reproducible public catalog data. Use a compatible client,
custom-format dump, checksums/manifest (schema/migrations/catalog/commit/
time), encrypted off-server transfer, retention and failure reporting.
Use systemd timers for recurring jobs; shell/pg tools suffice unless a
Python utility is actually needed. If used, Python runs through uv with
ruff and only needed libraries; use a least-privilege Postgres driver.

Only daybyword.com's entry in ubuntu-vm-backup may change. Protect role/
grant/bootstrap and environment recovery separately: a database dump does
not capture all cluster roles. Test restore into an isolated database,
reapply restricted grants, check catalog/migrations and app readiness.
Record a restore before first deploy and quarterly afterward. No backup
is proved by merely creating a file on the same server. Phase 14 must
update retention, consent and deletion behavior before storing reader data.
