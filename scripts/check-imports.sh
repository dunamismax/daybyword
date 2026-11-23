#!/bin/sh
# Fails if a shared package imports anything but Foundation, the system
# SQLite3 library, the project's own packages, or Swift Testing in tests.
# The packages must build on Linux, so Apple-only frameworks such as UIKit or
# SwiftUI never belong in them (AGENTS.md §5, BUILD.md P1.3).
set -eu
cd "$(dirname "$0")/.."

allowed_sources="Foundation SQLite3 CSQLite ReadingEngine ReadingData CatalogCompiler"
allowed_tests="$allowed_sources Testing"

status=0
check() {
  directory=$1
  allowed=$2
  [ -d "$directory" ] || return 0
  # Lines such as "import X", "@testable import X", "public import X".
  find "$directory" -name '*.swift' -print | sort | while read -r file; do
    grep -nE '^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*((public|package|internal|fileprivate|private)[[:space:]]+)?import[[:space:]]' "$file" |
      while IFS= read -r line; do
        module=$(printf '%s\n' "$line" | sed -E 's/.*import[[:space:]]+(class |struct |enum |protocol |func |var |let |typealias )?([A-Za-z_][A-Za-z0-9_]*).*/\2/')
        case " $allowed " in
          *" $module "*) ;;
          *) printf '%s:%s: import of %s is not allowed in a shared package\n' "$file" "${line%%:*}" "$module"
             echo fail ;;
        esac
      done
  done
}

output=$(
  for package in Packages/*/; do
    check "${package}Sources" "$allowed_sources"
    check "${package}Tests" "$allowed_tests"
  done
)
if printf '%s\n' "$output" | grep -q '^fail$'; then
  printf '%s\n' "$output" | grep -v '^fail$' >&2
  status=1
fi

# The app and its widgets make no network requests of their own (the
# privacy policy says so, and every feature works in airplane mode,
# BUILD.md P17.5): no networking API appears in their code. Links the
# reader opens go to the system (Link, openURL), which is not the app asking.
if grep -rnE '\b(URLSession|URLRequest|NWConnection|NWPathMonitor|WKWebView|SFSafariViewController|CFNetwork|dataTask|Network\.framework)\b|^import (Network|WebKit|SafariServices)$' \
  apple/App apple/Widgets apple/Shared Packages/ReadingEngine/Sources Packages/ReadingData/Sources >&2; then
  echo "check-imports: the app must make no network requests of its own (P17.5)" >&2
  status=1
fi
exit $status
