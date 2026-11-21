# Deployment

daybyword.com runs on the owner's host, `ubuntu-vm`, under the host's web
platform contract (`ubuntu-vm-backup/docs/web-platform.md`, adopted by the
owner on 2026-11-21): a native systemd service on the host's one Node, the
host's PostgreSQL 18 cluster, the shared Caddy, and fix-forward deploys that
check every release as a candidate before it takes traffic (decisions.md
E46). Nothing in production runs in a container. Where this file and the
contract disagree, the contract wins and this file is out of date.

## The live host

| Thing | Where |
|---|---|
| Web | `daybyword-web.service` (`deploy/systemd/daybyword-web.service`): `/opt/node-26/bin/node server.ts` (web/server.ts around adapter-node's build) from `/srv/www/daybyword.com/current`, as `daybyword-web` (system account, no login, no home), on `127.0.0.1:4318`, with the contract's sandbox and the drop-in `daybyword-web.service.d/50-resource-boundaries.conf` |
| Releases | `/srv/www/daybyword.com/releases/<full commit>/` (root-owned, never edited) and `current`, an absolute symlink; no pointer to any other release |
| Database | `daybyword` on the host cluster, `127.0.0.1:5432`, SCRAM over loopback only; every table in schema `app` (migration 0002) |
| Roles | `daybyword_owner` owns everything and cannot log in; `daybyword_migration` becomes it with `SET ROLE` for migrations and the catalog import; `daybyword_web` reads, in read-only transactions (`db/roles.sql` is the same model for tests) |
| Secrets | `/etc/web-apps/daybyword/` (0700 root; files 0600 root): `web.env` for the web unit, `migration.env` for the deploy's migration step only. No other secret exists at 1.0 |
| Backups | `/srv/www/daybyword.com/shared/backups/` (0700): nightly `daybyword-backup.timer` and a dump before each migration, each with its SHA-256 and manifest, 14 days; `daybyword-restore-check.timer` restores the newest monthly into a throwaway cluster. Off the server: ubuntu-vm-backup's daily encrypted dump of every database in the cluster |
| Caddy | `/etc/caddy/sites/daybyword.com.caddy` from `deploy/caddy/daybyword.com.caddy`, changed only through `caddy-apply` |
| What is live | `sudo ubuntu-vm-backup/bin/web-live daybyword-web.service` (release directory and revision from the running process) or `https://daybyword.com/healthz`; never a checkout |

DNS is the owner's DNS-only Cloudflare records; Caddy obtains its own Let's
Encrypt certificates. No DNS challenge, plugin, token, proxying or SSL-mode
work; agents never change Cloudflare settings. Caddy writes no access log:
the app logs one metadata-only line per request (method, route pattern,
status, time), never an address, query or body.

## Provisioning (once)

```sh
cd /home/sawyer/github/ubuntu-vm-backup
sudo with-deploy-lock bin/provision-app-database daybyword --web-access read-only
```

It creates the three roles, the database, schema `app`, `web.env`,
`migration.env` and their `pg_hba.conf` rules, and proves them with real
logins. Safe to repeat. The first deploy's migration then moves the restored
tables into `app` and grants the web role what it reads.

## Deploying

```sh
make deploy        # on the Mac, from a clean main equal to origin/main
```

`deploy/bin/release.sh` builds the release catalog export here (the catalog
compiler is Swift), copies it to the host, and then:

1. **Build**, on the host as `sawyer`, outside the lock: the commit's own
   `deploy/bin/build-release.sh` archives the commit into
   `/home/sawyer/web-work/daybyword.com-<commit>/`, installs with `pnpm
   install --frozen-lockfile`, and runs `pnpm run check`, `lint` and `test`,
   the export's check, the database tests and the production server's tests
   (throwaway PostgreSQL 18 clusters), and the adapter-node build. The
   release gets production dependencies only. A failure changes nothing.
2. **Activate**, one `with-deploy-lock` process as root, the release's
   `deploy/bin/activate.sh`:
   - stage it as `releases/<commit>`, root-owned, and continue from there;
   - `deploy/bin/backup.sh` (a checked dump);
   - `scripts/db-migrate.ts`, then `scripts/catalog-import.ts`, each as
     `daybyword-web` with `migration.env` only (`systemd-run`), and the
     migrations counted against the release's journal;
   - a **candidate**: a copy of the release's own unit file with the release
     directory and a free port in 4400–4499, started under systemd (same
     account, sandbox, env file and Node as will serve, against the real
     database), checked by `deploy/bin/check-live.sh` including
     `{"status":"ok","revision":"<commit>","database":"ok"}` from `/healthz`,
     and always removed;
   - the unit files installed if they changed (`systemd-analyze verify`
     first), `current` replaced atomically, the service restarted;
   - what is live checked: `/healthz` on 4318 with the commit,
     `check-live.sh`, and `web-live` (release directory, revision, Node
     26.13.1, state `current`);
   - Caddy only if the site file changed (`caddy-apply`);
   - `logger -t web-deploy`, `check-live.sh https://daybyword.com`, and the
     other sites answering as they did before.

**When a step fails** the script stops and says why. Up to the candidate the
previous release is still serving and nothing needs undoing. After the
switch there is no way back to an older release, and none is kept: read
`journalctl -u daybyword-web`, fix it in a new commit and deploy that, and
close the gap in the candidate check in the same commit. Restoring a dump
over the live database is a decision for the owner, never a deploy step.

**Migrations** must leave the serving release working, because it serves
through the migration and the candidate: add, never remove or rename in the
same release. The catalog is immutable once imported (E39); each release's
import adds an import and moves `catalog_current`, which the serving release
reads as its current catalog.

## Backups

`deploy/bin/backup.sh` dumps `daybyword` as the postgres superuser to a
temporary file and keeps it only if pg_dump finished, the file is not
empty, and `pg_restore --list` reads it and finds tables; anything else
exits non-zero and leaves nothing. Its manifest records the release, the
migrations and the current catalog's digest. `deploy/bin/restore-check.sh`
checks the newest dump's SHA-256, restores it into a cluster of its own (a
Unix socket in a private directory, no TCP port, deleted afterwards) with
`db/roles.sql`, and compares the migrations and the catalog with the
manifest and that `daybyword_web` reads the plans. Both run as root from the
serving release; neither touches the live database beyond the dump.

ubuntu-vm-backup's daily run dumps every database in the cluster with the
roles, encrypts them and keeps them off the server, and boots the archived
release against them (`config/applications.json`: entry `server.ts`,
database `daybyword`). `/etc/web-apps/daybyword/` and the units are in the
same backup.

## History

Until 2026-11-21 the site ran as the Compose project `daybyword`: the web in
`daybyword-web:<commit>` images and PostgreSQL in a `postgres:18.6` container
with the volume `daybyword_postgres_data` (E43, superseded by E46). The
move to the host cluster and the native unit, with the row counts it
checked, is in E46 and BUILD.md's notes.
