// The settings kept only in the reader's browser (BUILD.md P2.11), pinned by
// tests/fixtures/settings.json: each choice's form field, its values, and its
// localStorage key. /assets/theme.js applies them before the page paints and
// /assets/settings.js keeps them; the server never sees them, and no cookie
// is set. A test checks that both scripts use these keys.

export interface Setting {
  name: string;
  key: string;
  values: readonly string[];
  fallback: string;
}

export const settings: readonly Setting[] = [
  {
    name: "appearance",
    key: "dbw.appearance",
    values: ["automatic", "light", "dark"],
    fallback: "automatic",
  },
  {
    name: "reference-size",
    key: "dbw.reference-size",
    values: ["standard", "larger", "largest"],
    fallback: "standard",
  },
];
