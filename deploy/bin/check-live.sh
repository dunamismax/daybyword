#!/bin/sh
# Checks a running daybyword.com from outside (BUILD.md P7.6): the health
# check, every section, a 404, the security headers and strict policy, no
# third-party loads, and no cookie; /healthz, with the release's commit when
# one is given. With an https:// base it also checks the certificate and the
# www redirect. It only reads. deploy/bin/activate.sh runs it on the
# candidate, the live port and https://daybyword.com.
#
#   deploy/bin/check-live.sh https://daybyword.com [COMMIT]
#   deploy/bin/check-live.sh http://127.0.0.1:4318 [COMMIT]
set -eu
base=${1:?usage: check-live.sh BASE-URL [COMMIT]}
base=${base%/}
commit=${2:-}
problems=0
problem() { printf 'check-live: %s\n' "$*" >&2; problems=$((problems + 1)); }

status() { curl -sS -o /dev/null -w '%{http_code}' "$base$1"; }

[ "$(curl -fsS "$base/up" 2>/dev/null)" = "OK" ] || problem "/up is not OK"
health=$(curl -fsS "$base/healthz" 2>/dev/null || true)
case $health in
'{"status":"ok","revision":"'"${commit:-}"*'","database":"ok"}') ;;
*) problem "/healthz answered ${health:-nothing}${commit:+; expected revision $commit and a database}" ;;
esac
for path in / /today /plans /progress /settings /plans/gospels-at-your-pace; do
  [ "$(status "$path")" = 200 ] || problem "$path answered $(status "$path")"
done
[ "$(status /no-such-page)" = 404 ] || problem "an unknown address is not 404"
[ "$(status /dev/components)" = 404 ] || problem "the component gallery is served"
curl -fsS "$base/robots.txt" | grep -q '^Disallow: /$' || problem "robots.txt does not block crawling (P7.7)"

headers=$(curl -fsS -D - -o /dev/null "$base/today")
for header in 'content-security-policy: default-src' 'x-content-type-options: nosniff' \
  'referrer-policy: no-referrer' 'x-frame-options: DENY' 'permissions-policy: ' \
  'cross-origin-opener-policy: same-origin' 'cache-control: no-cache'; do
  printf '%s' "$headers" | grep -qi "^$header" || problem "/today lacks $header"
done
printf '%s' "$headers" | grep -i '^content-security-policy:' | grep -qi 'unsafe-' && problem "the policy allows unsafe-*"
printf '%s' "$headers" | grep -qi '^set-cookie:' && problem "/today sets a cookie"
printf '%s' "$headers" | grep -qi '^x-dbw-route:' && problem "the route marker leaks"

for path in / /today /settings; do
  page=$(curl -fsS "$base$path")
  printf '%s' "$page" | grep -Eqi '(src|href)="(https?:)?//' && problem "$path loads from another host"
  printf '%s' "$page" | grep -q 'name="robots" content="noindex"' || problem "$path is not noindex (P7.7)"
  sheet=$(printf '%s' "$page" | grep -oE 'href="\.?/_app/immutable/assets/[^"]+\.css"' | head -n 1 | sed -E 's/^href="\.?//; s/"$//')
  [ -n "$sheet" ] && [ "$(status "$sheet")" = 200 ] || problem "$path's stylesheet does not load"
done

case $base in
https://*)
  host=${base#https://}
  [ "$(curl -sS -o /dev/null -w '%{http_code} %{redirect_url}' "https://www.$host/plans?x=1")" = "301 https://$host/plans?x=1" ] ||
    problem "www does not redirect permanently, keeping the path and query"
  curl -fsS -o /dev/null "$base/up" || problem "the certificate does not verify"
  curl -fsS -D - -o /dev/null "$base/up" | grep -qi '^strict-transport-security:' || problem "no HSTS"
  ;;
esac

[ "$problems" -eq 0 ] || { echo "check-live: $problems problem(s) at $base" >&2; exit 1; }
echo "check-live: $base answers as it should${commit:+ (revision $commit)}"
