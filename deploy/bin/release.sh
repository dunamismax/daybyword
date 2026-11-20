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
if ssh -o BatchMode=yes "$host" "test \"\$(cat '$root/current-release')\" = '$sha' && test \"\$(readlink -f '$root/current')\" = '$dir'"; then
  deploy/bin/check-live.sh https://daybyword.com
  exit 0
fi
stage=$(ssh -o BatchMode=yes "$host" "mktemp -d '$root/.staging.XXXXXXXX'")
case "$stage" in "$root"/.staging.*) ;; *) exit 1 ;; esac
trap 'ssh -o BatchMode=yes "$host" "rm -rf -- $stage"' EXIT
git archive --format=tar "$sha" | ssh -o BatchMode=yes "$host" "tar -x -C '$stage' && mkdir -p '$stage/build/catalog'"
scp -q build/catalog/catalog-export.json "$host:$stage/build/catalog/"
ssh -o BatchMode=yes "$host" "with-deploy-lock sh -s -- '$stage' '$dir' '$sha' '$root'" <<'REMOTE'
set -eu
stage=$1 dir=$2 sha=$3 root=$4
if [ ! -d "$dir" ]; then
  chmod 0755 "$stage"
  mv -T "$stage" "$dir"
elif ! diff -qr "$stage" "$dir" >/dev/null; then
  echo "existing release differs from the staged commit" >&2
  exit 1
fi
cd "$dir"
DBW_RELEASE=$sha deploy/bin/deploy.sh
test "$(cat "$root/current-release")" = "$sha"
test "$(readlink -f "$root/current")" = "$dir"
REMOTE
deploy/bin/check-live.sh https://daybyword.com
