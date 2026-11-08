#!/bin/sh
# Boots the production Astro build (web/dist, Node standalone) on a free
# loopback port and checks that it serves the health check and a prerendered
# page, so `make check` proves the real production output (BUILD.md PM.13).
set -eu
cd "$(dirname "$0")/../web"

# A free loopback port, unless DBW_SMOKE_PORT names one.
port=${DBW_SMOKE_PORT:-$(node -e 'const s=require("node:net").createServer();s.listen(0,"127.0.0.1",()=>{console.log(s.address().port);s.close()})')}
base="http://127.0.0.1:$port"
log=$(mktemp)
HOST=127.0.0.1 PORT=$port node ./dist/server/entry.mjs >"$log" 2>&1 &
pid=$!
trap 'kill $pid 2>/dev/null || true; rm -f "$log"' EXIT INT TERM

i=0
until curl -fsS "$base/up" >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -gt 50 ] || ! kill -0 "$pid" 2>/dev/null; then
    echo "web-smoke: the server did not start" >&2
    cat "$log" >&2
    exit 1
  fi
  sleep 0.1
done

fail() { echo "web-smoke: $1" >&2; exit 1; }

headers=$(curl -fsS -D - -o /dev/null "$base/up")
body=$(curl -fsS "$base/up")
[ "$body" = "OK" ] || fail "/up answered '$body', not OK"
printf '%s' "$headers" | grep -qi '^content-type: text/plain; charset=utf-8' || fail "/up content type"
printf '%s' "$headers" | grep -qi '^cache-control: no-store' || fail "/up is not no-store"

page=$(curl -fsS "$base/")
printf '%s' "$page" | grep -q '<title>Day by Word</title>' || fail "/ has no title"
if printf '%s' "$page" | grep -Eqi '(src|href)="(https?:)?//'; then
  fail "/ loads something from another host"
fi

status=$(curl -s -o /dev/null -w '%{http_code}' "$base/no-such-page")
[ "$status" = "404" ] || fail "an unknown address answered $status, not 404"

echo "web-smoke: production build serves /up, /, and 404 on $base"
