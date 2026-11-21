#!/bin/sh
# Deploys origin/main to daybyword.com from this Mac (make deploy;
# docs/deploy.md, "Deploying"):
#
# 1. refuses anything but a clean checkout equal to origin/main;
# 2. builds the release catalog export from it here (the catalog compiler is
#    Swift) and copies it to the host;
# 3. on the host, as the checkout owner and outside the lock, runs that
#    commit's own deploy/bin/build-release.sh with the pinned Node and pnpm;
# 4. inside one with-deploy-lock process, as root, runs the built release's
#    deploy/bin/activate.sh: backup, migrate, candidate, switch, verify.
#
#   make deploy                      DBW_HOST=root@ubuntu-vm by default
set -eu
cd "$(dirname "$0")/../.."
host=${DBW_HOST:-root@ubuntu-vm}
checkout=/home/sawyer/github/daybyword

git fetch -q origin
[ -z "$(git status --porcelain)" ] || { echo "release: the checkout has changes" >&2; exit 1; }
sha=$(git rev-parse HEAD)
[ "$sha" = "$(git rev-parse origin/main)" ] || { echo "release: HEAD is not origin/main" >&2; exit 1; }

make --no-print-directory catalog-export >/dev/null
export_file=/home/sawyer/web-work/daybyword.com-$sha.catalog-export.json
ssh -o BatchMode=yes "$host" "install -d -o sawyer -g sawyer /home/sawyer/web-work"
scp -q build/catalog/catalog-export.json "$host:$export_file"
ssh -o BatchMode=yes "$host" "chown sawyer:sawyer '$export_file' && runuser -u sawyer -- /usr/local/bin/node-26 sh -c '
  set -eu
  git -C $checkout fetch -q origin
  script=\$(mktemp)
  git -C $checkout show $sha:deploy/bin/build-release.sh >\"\$script\"
  status=0
  sh \"\$script\" $sha $export_file || status=\$?
  rm -f \"\$script\"
  exit \$status'"
ssh -o BatchMode=yes "$host" \
  "/usr/local/sbin/with-deploy-lock /home/sawyer/web-work/daybyword.com-$sha/release/deploy/bin/activate.sh $sha"
