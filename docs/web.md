# The web's JavaScript and CSS

daybyword.com is rendered on the server (docs/decisions.md E11, E19). The
project's own JavaScript adds the web app's interactivity, and its own CSS
styles every page. This note is the style guide for both; Swift is formatted
by `swift format` with the repository's `.swift-format` and linted by
`make check`.

## Rules for both

- **Everything is ours.** No npm, no bundler, no framework, no third-party
  script, stylesheet, or font, and nothing loaded from another host
  (AGENTS.md §5). The Content Security Policy enforces it.
- **Modern browsers only** (D30): the current and previous major versions
  of Safari, Chrome, Firefox, and Edge. Use what they all support without a
  prefix or a polyfill; older browsers get a plain notice.
- **Files live in `Server/Public/`**, are served as they are written, and
  are small enough to read in one sitting.
- Two-space indentation, UTF-8, a final newline, and lines under 100
  characters.

## JavaScript

- ES modules only (`<script type="module" src="/assets/…">`), with no inline
  scripts and no `eval`, so the CSP never needs `unsafe-inline` or
  `unsafe-eval`.
- `const` by default, `let` when a value changes, never `var`. Strict
  equality. Semicolons at the end of statements.
- Named exports, one module per job (for example `marking.js`,
  `offline.js`), and no globals.
- **No engine logic.** The browser never decides what to read, whether a day
  is complete, or what a catch-up choice does; it asks the server, which
  asks `ReadingEngine` (E4). JavaScript renders answers, sends the reader's
  actions, and queues them while offline.
- Progressive enhancement where it is cheap: links and forms work as plain
  HTML first, and scripts improve them.
- Talk to the server with `fetch` and JSON. Never put personal data in a URL
  (E17).
- Interface text comes from the server's string tables (E15), rendered into
  the page or returned by the API, never written in a script.
- No `localStorage` for reading data; the offline queue lives in IndexedDB
  and holds only what the reader has chosen to keep (D10).
- Name things for what they are in the reader's words: `reading`, `plan`,
  `today`, `markRead`.

## CSS

- One stylesheet per concern (`site.css` for the layout, `tokens.css`
  generated from `design/tokens.json`), loaded with `<link>`; no inline
  styles, so the CSP never needs `unsafe-inline` for styles.
- **No raw colors.** Every color is a custom property from the generated
  `tokens.css` (E12). Until the tokens exist, placeholder pages use CSS
  system colors (`Canvas`, `CanvasText`).
- Light and dark follow `prefers-color-scheme`, and the reader's own choice
  in Settings overrides it.
- Sizes in `rem` so that text scales with the reader's settings; layouts
  hold at 320 CSS pixels and at 200% text (WCAG 2.2 AA).
- Class names describe what a thing is (`.reading`, `.plan-card`), in
  lowercase with hyphens. No utility-class systems.
- Respect `prefers-reduced-motion`; keep visible focus styles on every
  control.
