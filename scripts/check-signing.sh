#!/bin/sh
# Checks that this Mac can sign and upload the app: Xcode installed, an Apple
# Development or Distribution certificate for the team in Base.xcconfig (or
# Secrets.xcconfig) in the login keychain, and Xcode signed in to an Apple ID.
# Automatic signing makes the distribution certificate and profiles itself
# during make archive and make testflight (docs/release.md, E48).
set -eu
cd "$(dirname "$0")/.."

team=$(sed -n 's/^DEVELOPMENT_TEAM *= *\([A-Z0-9]*\).*/\1/p' apple/Config/Base.xcconfig apple/Config/Secrets.xcconfig 2>/dev/null | tail -n 1)
problems=0
fail() {
  echo "signing: $1" >&2
  problems=1
}

[ -n "$team" ] || fail "no DEVELOPMENT_TEAM in apple/Config/Base.xcconfig"
command -v xcodebuild >/dev/null || fail "Xcode is not installed"

found=""
for hash in $(security find-identity -v -p codesigning 2>/dev/null | awk '/Apple (Development|Distribution)/ { print $2 }'); do
  ou=$(security find-certificate -a -Z -p 2>/dev/null | awk -v h="$hash" '
    /^SHA-1 hash:/ { keep = ($3 == h) } keep && /BEGIN CERT/,/END CERT/ { print } /END CERT/ { keep = 0 }' |
    openssl x509 -noout -subject 2>/dev/null | sed -n 's/.*OU *= *\([A-Z0-9]*\).*/\1/p')
  [ "$ou" = "$team" ] && found=$hash
done
[ -n "$found" ] || fail "no signing certificate for team $team; open Xcode → Settings → Accounts, sign in, and choose Manage Certificates → +"

accounts=$(defaults read com.apple.dt.Xcode DVTDeveloperAccountManagerAppleIDLists 2>/dev/null | grep -c identifier || true)
[ "$accounts" -gt 0 ] || fail "Xcode is not signed in to an Apple ID (Xcode → Settings → Accounts)"

[ "$problems" -eq 0 ] || exit 1
echo "signing: ready for team $team"
