# SvelteKit/PostgreSQL deployment plan

**D41, as D42 revised it (2026-11-20).** PM.18 built the files below and
rehearsed them on the owner's Mac in Docker (`make rehearse-deploy`).
**daybyword.com went live on 2026-11-20** (P7): see "The live host". No
server SQLite, Litestream or mandatory Python service.

## The live host (2026-11-20)

- ubuntu-vm: Ubuntu 26.04.1, x86_64, Docker 29.10 with Compose v5.8, the
  system Caddy 2.11.9 (a custom build with caddy-ratelimit) importing
  `/etc/caddy/sites/*.caddy`. DNS for daybyword.com and www points at the
  host directly.
- `/srv/www/daybyword.com/`: `releases/<commit>`, `current` (symlink),
  `current-release`, `previous-release`, `shared/env` (root 0600, hex
  passwords generated on the host), `shared/backups` (0700).
- Compose project `daybyword`: web on 127.0.0.1:4318 (4316 and 4317 belong
  to other sites), candidate checks on 4319, PostgreSQL 18.6 on the
  internal network only, volume `daybyword_postgres_data`. The host's own
  PostgreSQL on 127.0.0.1:5432 is untouched.
- Lock: `with-deploy-lock` (flock on `/run/web-deploy/lock`).
- Caddy: `/etc/caddy/sites/daybyword.com.caddy` only; `/etc/caddy` was
  archived first to `/root/caddy-archives/`; validated, then reloaded.
- Timers: `daybyword-backup.timer` (nightly) and
  `daybyword-restore-check.timer` (monthly); the first backup and restore
  check ran on the host and passed.
- **Not yet:** an encrypted off-server copy of `shared/backups`. No
  `ubuntu-vm-backup` checkout or backup tool was found on the host or the
  Mac; the owner's existing off-server arrangement must be found (or one
  agreed) before P7.3 is done.
- Every other site's name answered the same before and after (20 names).

## The files (PM.18)

| File | What it does |
|---|---|
| `deploy/Dockerfile` | The web image: `vite build`, then a runtime stage with only drizzle-orm and pg, `server.ts`, the jobs, `drizzle/` and the release's catalog export, as the unprivileged `node` user; Node pinned by index digest |
| `deploy/compose.yaml` | Project `daybyword`: `postgres` (18.6, pinned by digest; volume `daybyword_postgres_data` at `/var/lib/postgresql`; internal network, no host port), `web` (read-only root, no capabilities, 127.0.0.1:4318 → 3000, waits for a healthy database), and the `migrate` job (profile `jobs`) |
| `deploy/postgres/init.sh` | On a new volume only: `web/db/roles.sql` and the two roles' passwords from the env file |
| `deploy/bin/deploy.sh` | Under the shared lock: build the image, start the database, reapply the roles, back up, migrate and import, check a candidate on 127.0.0.1:4319, activate, check, record `current-release`; rolls back if the activated release fails |
| `deploy/bin/rollback.sh` | Switches the web back to `previous-release`'s image, keeping the database |
| `deploy/bin/check-live.sh` | Checks a base URL: `/up`, the sections, 404s, headers and policy, no cookie or third-party load, noindex, stylesheet; with https, also www's redirect, the certificate and HSTS (P7.6) |
| `deploy/bin/backup.sh` | `pg_dump` (custom format) with SHA-256 and a manifest (release, migrations, catalog digest), 14 days kept in `shared/backups` (0700) |
| `deploy/bin/restore-check.sh` | Restores the newest dump into a throwaway PostgreSQL with no network, recreates the roles, checks migrations, catalog and the web role's reads against the manifest |
| `deploy/systemd/` | `daybyword-backup.timer` (nightly 03:20) and `daybyword-restore-check.timer` (monthly), checked with `systemd-analyze verify` |
| `deploy/caddy/daybyword.com.caddy` | The site file: apex to 127.0.0.1:4318 with HSTS, www redirected permanently with path and query, no access log |
| `deploy/bin/release.sh` | `make deploy`: from a clean checkout equal to origin/main, builds the export, unpacks the commit and export into `releases/<commit>` on the host, runs `deploy.sh` inside `with-deploy-lock`, then `check-live.sh https://daybyword.com` |
| `deploy/bin/rehearse.sh` | The whole cycle on a throwaway project: deploy, backup, restore check, role limits, redeploy, rollback, logs, teardown |

The env file (`shared/env`, root 0600) holds `POSTGRES_PASSWORD`,
`DBW_APP_PASSWORD` and `DBW_MIGRATE_PASSWORD` (hex); the scripts take
`DBW_ROOT`, `DBW_PORT`, `DBW_DEPLOY_LOCK` (required: the host's lock, P7.1)
and `DBW_RELEASE` from the environment. `/up` answers OK only once the
database answers and a catalog is current, as the read-only web role.
Encryption and the off-server copy of `shared/backups` are the host's
`ubuntu-vm-backup` entry (P7.3).

## Isolation and layout

| Resource | Planned convention; inspect before use |
|---|---|
| Host | ubuntu-vm under D34; existing shared Caddy |
| Release root | /srv/www/daybyword.com/releases/<commit>, current pointer |
| Persistent resources | shared/env (root-owned 0600), shared/storage, shared/backups |
| Source files | deploy/compose.yaml, deploy/Dockerfile, deploy/caddy/daybyword.com |
| Compose project | daybyword; web (adapter-node), postgres (PostgreSQL 18), one-shot migration/catalog import |
| Web listener | adapter-node in the container on 0.0.0.0:3000 (`HOST`, `PORT`), published only at 127.0.0.1:4318 (4316 and 4317 are other sites') |
| Postgres | private Docker network port 5432; no production host port |
| DB/role | daybyword; `daybyword_app` (web, read-only) and `daybyword_migrate` (migration/import jobs), from `web/db/roles.sql` (PM.14) |
| Volume | explicit daybyword_postgres_data; stable across release directories |
| Host Caddy site | /etc/caddy/sites/daybyword.com.caddy, imported by the main Caddyfile's `import /etc/caddy/sites/*.caddy` |
| Health | /up, no-store, ready only with compatible DB/catalog |
| Shared deploy lock | the host's `with-deploy-lock COMMAND` (flock on `/run/web-deploy/lock`, fd 9), which the scripts recognise |

Record other sites' responses before/after every server change. Archive
/etc/caddy before touching it. Add only this site's configuration; never
edit another site's file, DB, service, user or backup entry. No second
Caddy, Coolify or Dokploy. Missing shared DNS modules need coordinated
host work, not unilateral proxy replacement. No live host access occurred
for this documentation revision.

## Application and secrets

Use @sveltejs/adapter-node: `vite build` writes `web/build/`, run as
`node server.ts` (in `web/`), which wraps adapter-node's handler so every
response carries the security headers, a cache policy and a metadata-only
log line (E38). This app needs runtime API/form-action/database
work; static public routes may prerender. A pure static content deployment
can be served directly by Caddy, but it cannot replace runtime APIs.
Build a pinned non-root Node image from a clean origin/main archive: build
in one stage, then copy `web/build/`, `web/server.ts`, `package.json`, the lockfile's
production dependencies (`npm ci --omit=dev`: drizzle-orm and pg, which
adapter-node leaves external), the jobs' `scripts/` and `src/lib/server/`,
and `drizzle/`, and test the actual image. PostgreSQL's image is the
pinned 18 major. No checkout as web root or runtime bind mount.

Document runtime HOST/PORT, DBW_ENV (production; `development` serves
/dev/components), the public origin (SvelteKit 3 removed adapter-node's
`ORIGIN`: Caddy passes the Host header and adapter-node assumes https, or
set `paths.origin` in `web/vite.config.ts` at build when form actions
arrive), `BODY_SIZE_LIMIT`, DBW_DATABASE_URL (the web as
daybyword_app; the jobs as daybyword_migrate, PM.14), DBW_COMMIT and catalog digest/schema. Existing Swift DBW_HOST,
DBW_PORT, DBW_PUBLIC_DIR and DBW_CATALOG need explicit mapping/removal.
Only public config may use client-exposed environment variables. No secrets
in build args, layers, logs, JS/native bundles or repository. Framework/
build telemetry is disabled. No auth/model/billing secret is needed at 1.0.

Postgres readiness must precede one-shot migration/import and candidate
readiness. Use bounded connection pools, restart/resource/log limits and
graceful shutdown. Persist only project data; never down -v during release.

## Proxy/TLS

DNS is owner-managed, DNS-only (not proxied) Cloudflare records pointing at
the server's public IP; host Caddy is the reverse proxy and obtains and renews
its own Let's Encrypt certificates. There is no Cloudflare DNS challenge,
caddy-dns plugin, Caddy Cloudflare token or SSL/TLS-mode setting in this
stack: do not plan or add any. Record changes and Cloudflare account settings
are the owner's; shared binary changes need coordination.
Verify apex HTTPS, permanent www redirect retaining path/query, renewal,
headers and the SvelteKit build's actual CSP and hydration behavior. No remote resources.
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
   routes/assets/SSR, form actions and hydration, CSP and matching catalog digest.
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
