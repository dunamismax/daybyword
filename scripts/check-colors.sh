#!/bin/sh
# Fails if a view, page, or stylesheet writes a raw color instead of using the
# design tokens (docs/design.md, BUILD.md P2.4). Colors come only from
# design/tokens.json, through the generated Palette (Swift) and tokens.css (web).
set -eu
cd "$(dirname "$0")/.."

status=0
report() {
  found=$1
  label=$2
  if [ -n "$found" ]; then
    printf '%s\n' "$found" | while IFS= read -r line; do printf '%s  <- %s\n' "$line" "$label"; done >&2
    status=1
  fi
}

primitives='red|orange|yellow|green|mint|teal|cyan|blue|indigo|purple|pink|brown|white|gray|grey|black'

# Swift in the app and widgets: color initializers, literals, and SwiftUI's
# fixed named colors. The generated DesignTokens.swift names asset colors only.
swift_files=$(find apple -name '*.swift' -not -name 'DesignTokens.swift' | sort)
if [ -n "$swift_files" ]; then
  report "$(grep -nE "Color\((red|white|hue|\.sRGB|\.displayP3|uiColor)|UIColor\(|#colorLiteral|Color\(\"#" $swift_files || true)" "raw color"
  report "$(grep -nE "(Color|UIColor)\.($primitives)([^A-Za-z]|\$)|\(\.($primitives)\)|: \.($primitives)([^A-Za-z]|\$)" $swift_files || true)" "fixed system color; use Palette"
fi

# The server's Swift writes HTML: no inline styles (the CSP forbids them too) and
# no color values.
server_files=$(find Server/Sources -name '*.swift' | sort)
report "$(grep -nE 'style="|#[0-9A-Fa-f]{6}([^0-9A-Za-z_-]|$)|rgba?\(|hsla?\(' $server_files || true)" "inline style or raw color in HTML"

# Stylesheets other than the generated tokens.css.
css_raw='#[0-9A-Fa-f]{3,8}([^0-9A-Za-z_-]|$)|(rgb|rgba|hsl|hsla|hwb|lab|lch|oklab|oklch|color)\('
css_named=":[[:space:]]*($primitives)([^A-Za-z-]|\$)"
css_files=$(find Server/Public -name '*.css' -not -name 'tokens.css' | sort)
if [ -n "$css_files" ]; then
  report "$(grep -nE "$css_raw|$css_named" $css_files || true)" "raw color; use a --color- token"
fi

exit $status
