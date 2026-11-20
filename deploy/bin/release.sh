#!/bin/sh
# Deploys origin/main to daybyword.com from this machine (make deploy;
# docs/deploy.md, BUILD.md P7.2): refuses anything but a clean checkout equal
# to origin/main, builds the release catalog export from it, unpacks that
# exact commit (git archive) and the export into
# /srv/www/daybyword.com/releases/<commit> on the host, runs
# deploy/bin/deploy.sh there inside the host's with-deploy-lock, and checks
# the public site.
#
#   make deploy                      DBW_HOST=root@ubuntu-vm by default
set -eu
cd "$(dirname "$0")/../.."
host=${DBW_HOST:-root@ubuntu-vm}
root=/srv/www/daybyword.com

git fetch -q origin
[ -z "$(git status --porcelain)" ] || { echo "release: the checkout has changes" >&2; exit 1; }
sha=$(git rev-parse HEAD)
[ "$sha" = "$(git rev-parse origin/main)" ] || { echo "release: HEAD is not origin/main" >&2; exit 1; }

make --no-print-directory catalog-export >/dev/null
dir="$root/releases/$sha"
ssh -o BatchMode=yes "$host" "test -f $root/shared/env && rm -rf $dir && mkdir -p $dir/build/catalog"
git archive --format=tar "$sha" | ssh -o BatchMode=yes "$host" "tar -x -C $dir"
scp -q build/catalog/catalog-export.json "$host:$dir/build/catalog/"
ssh -o BatchMode=yes "$host" "cd $dir && DBW_RELEASE=$sha with-deploy-lock deploy/bin/deploy.sh" 2>&1 |
  grep -vE '^ (Container|Network|Volume|Image) |^ [0-9a-f]{12} '
deploy/bin/check-live.sh https://daybyword.com
