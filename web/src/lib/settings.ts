// The settings kept only in the reader's browser (BUILD.md P2.11), pinned by
// tests/fixtures/settings.json: each choice's form field, its values, and its
// localStorage key. /assets/theme.js applies them before the page paints and
// /assets/settings.js keeps them; the server never sees them, and no cookie
// is set. A test checks that both scripts use these keys.

import { bibleTranslations, namingConventions } from "#lib/domain/index.ts";

export interface Setting {
  name: string;
  key: string;
  values: readonly string[];
  fallback: string;
  /** Whether /assets/theme.js applies it to the page before it paints. */
  applied: boolean;
}

export const settings: readonly Setting[] = [
  {
    name: "appearance",
    key: "dbw.appearance",
    values: ["automatic", "light", "dark"],
    fallback: "automatic",
    applied: true,
  },
  {
    name: "reference-size",
    key: "dbw.reference-size",
    values: ["standard", "larger", "largest"],
    fallback: "standard",
    applied: true,
  },
  // Read by /assets/reading.js and sent with the journal to /api/v1/today,
  // which shows the place in print or the link to open (P8.10d).
  {
    name: "way-to-read",
    key: "dbw.way-to-read",
    values: ["physicalBible", "youVersion", "otherApp"],
    fallback: "physicalBible",
    applied: false,
  },
  {
    name: "translation",
    key: "dbw.translation",
    // 0 until the reader chooses one; then Bible.com's version number
    // (docs/destinations.md, "Translations").
    values: ["0", ...bibleTranslations.map((translation) => String(translation.id))],
    fallback: "0",
    applied: false,
  },
  {
    name: "book-names",
    key: "dbw.book-names",
    values: namingConventions,
    fallback: "common",
    applied: false,
  },
];
