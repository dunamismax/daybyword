# Deployment plan

**Planned, not provisioned or verified live (2026-11-02).** D40 replaces
the former Swift/systemd/no-Docker design. Phase M builds the files below;
P7 provisions and deploys them. This document is not evidence that a port,
path, module, database, certificate, backup job, or service already exists.

## Project boundaries

Host: `ubuntu-vm`, reached under D34's standing permission. Root operations
are limited to this project's resources. Record the other sites' HTTP
results before and after every server change, use the host's existing
shared deploy lock (discover and record its exact path before use), and
archive `/etc/caddy` before any Caddy change. Never edit another site's
configuration, database, service, proxy, or backup entry.

| Resource | Planned convention |
|---|---|
| Source | Clean `origin/main` archive; main pushes to GitHub and Codeberg |
| Root | `/srv/www/daybyword.com`; checkout is never a web root |
| Releases | `releases/<commit>/` with immutable Compose configuration/image reference; `current` selects the active release |
| Persistent files | `shared/env` (root-owned 0600), `shared/storage`, `shared/backups`; no secrets in releases/images |
| Compose source | `deploy/compose.yaml`; project name `daybyword`; web, postgres and one-shot migration/import jobs |
| Data volume | Explicit project volume `daybyword_postgres_data`, stable across release directories; never `down -v` during deploy/rollback |
| Web listener | Container `0.0.0.0:3000` published only at `127.0.0.1:4316`; check availability first and record any replacement |
| Candidate listener | A verified free loopback port for smoke testing; never displace another app |
| Postgres | `postgres:5432` inside the project's private Docker network; no host port mapping in production |
| Database / role | `daybyword` / `daybyword_app`; separate protected migrator/import role; no shared app role or superuser runtime |
| Proxy source / host file | `deploy/caddy/daybyword.com` → `/etc/caddy/sites/daybyword.com`, after confirming host includes that directory |
| Domains | `daybyword.com`; permanent `www` → apex redirect retaining path/query |
| Readiness | `/up`, no-store; checks app and compatible catalog/DB availability, returns no secret data |

Use a dedicated Compose Postgres service for this project. Reusing a
native Postgres service is permitted only after inspecting it and keeping
an isolated database/roles without altering another project's setup.
Do not install a second Caddy, Coolify, or Dokploy. Keep the host proxy.

## Runtime and secrets

The web image is a pinned, multi-stage, non-root Node build with Next
`output: 'standalone'`. Copy standalone output, `public`, `.next/static`,
workspace runtime files and the release catalog. Set the monorepo tracing
root. Test the image itself; a passing dev server is insufficient.
Keep migration/import tooling and generated SQL available in a separate
build target/job. Do not install tools into a running production container.

Document and validate runtime `NODE_ENV`, `HOSTNAME`, `PORT`,
`DATABASE_URL`, separate migration credentials, `DBW_COMMIT`, public origin
and catalog version/digest. These replace `DBW_HOST`, `DBW_PORT`,
`DBW_PUBLIC_DIR` and `DBW_CATALOG` from the Swift server.
Only public configuration may have a `NEXT_PUBLIC_` or `EXPO_PUBLIC_` prefix.
No signing key, database URL or secret may appear in a bundle, build arg,
image layer, repository, log or diagnostic page. Disable framework/tool
telemetry. No auth, Stripe, VAPID or model secret is needed at 1.0.

Use Postgres readiness and explicit Compose dependency conditions; process
startup alone is not database readiness. Bound resources and log retention,
restart policy and graceful shutdown are part of PM.8. Retain shared data
and do not overwrite it when replacing images.

## Caddy and Cloudflare

Inspect the host Caddy version, module list, imported site-file convention,
certificate setup and service environment before preparing changes.
Use the `caddy-dns/cloudflare` module and ACME DNS challenge with a token
scoped to daybyword.com's DNS when available. The token belongs in
protected host Caddy environment, never a site file or client bundle.
If the shared binary lacks the module, record the dependency and prepare
a tested custom-build/rollback procedure for the owner to coordinate;
replacing the shared Caddy binary is outside a daybyword-only site edit.
An existing valid certificate can serve during that coordination.

The owner verifies Cloudflare settings: proxied DNS uses **Full (strict)**,
with a valid origin certificate; never Flexible. Do not sign in as the
owner. Verify apex/www DNS, origin and public HTTPS, renewal and redirects.
Archive config, validate it, reload, and compare other-site checks.
Keep HSTS and security headers coordinated with the app's nonce CSP;
never replace its CSP with a conflicting static policy.
No CDN caching of private API results or nonce-bearing HTML. Access logs
must omit/redact concrete plan paths, query strings, bodies, tokens and
cookies, keeping method, route pattern, status and duration only.

## Release sequence and rollback

PM builds and rehearses this sequence locally; P7 executes it on the host.

1. Run `make check-full`; push main. Under the shared lock, resolve a clean
   `origin/main` commit, record the active image/config/schema/catalog, and
   build the immutable candidate. No bind-mounted repository as runtime.
2. Back up the project DB before migrations. Start/verify Postgres and run
   reviewed Drizzle SQL once with the migrator role, then transactionally
   import the compiler's release artifact. No production `drizzle-kit push`.
3. Boot the candidate on a spare loopback port, check readiness, routes,
   assets, SSR, CSP/hydration and catalog digest. Migrations must remain
   compatible with the active release during this check.
4. Switch only daybyword's active web container/config, retaining the old
   image and release pointer. Check public apex/www, headers, TLS and
   `make check-live`; compare the other sites again.
5. On failure restore the previous compatible image/config. A code
   rollback never automatically undoes a destructive DB migration.
   Prefer expand/contract SQL; rehearse restore separately when schema
   compatibility cannot be kept. Never restore over newer reader records
   without a reviewed recovery procedure.

Until launch retain the in-development line, `noindex` and robots block.
Record the actual commit, image digest, paths, lock and checks in the
handoff after provisioning; no placeholder value is a successful deploy.

## Nightly backup and restore

Start nightly `pg_dump` backups with the first Postgres deployment, even
though version 1.0 holds only reproducible catalog data. Use a compatible
client and custom-format dump, protected credentials, checksum/manifest
(DB version, schema migrations, catalog digest, app commit, time), encrypted
off-server copying through only daybyword.com's `ubuntu-vm-backup` entry,
and explicit retention and failure reporting. Keep a temporary dump out
of public directories and remove it after verified encrypted transfer.
Back up role/bootstrap requirements and protected configuration separately;
`pg_dump` of one database alone does not capture cluster roles.

Test `pg_restore` into a separate database with least-privilege grants,
check catalog/migration invariants and application readiness, and record
the result before first production deployment and quarterly thereafter.
A file existing on the server is not an off-server or restore test.
Once Phase 14 stores reader data, update consent, deletion/backup expiry
and the restore procedure before collecting any of it.
