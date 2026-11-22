// Everything Day by Word keeps in a reader's browser (BUILD.md P16.4), for
// the privacy policy's statement of cookies and browser storage. The names
// are the code's own (static/assets/reading.js, src/lib/settings.ts, the
// service worker); a unit test refuses a name the code uses that is missing
// here, so the statement stays complete. There are no cookies.
import { settings } from "#lib/settings.ts";
import type { StringKey } from "#lib/strings.ts";

export interface StoredItem {
  where: StringKey;
  name: string;
  holds: StringKey;
  why: StringKey;
}

const setting = (name: string) => {
  const key = settings.find((each) => each.name === name)?.key;
  if (key === undefined) throw new Error(`no setting named ${name}`);
  return key;
};

export const storedItems: readonly StoredItem[] = [
  {
    where: "privacy.where-indexeddb",
    name: "day-by-word / events",
    holds: "privacy.holds-events",
    why: "privacy.why-events",
  },
  {
    where: "privacy.where-indexeddb",
    name: "day-by-word / pending",
    holds: "privacy.holds-pending",
    why: "privacy.why-pending",
  },
  {
    where: "privacy.where-local",
    name: setting("appearance"),
    holds: "privacy.holds-appearance",
    why: "privacy.why-appearance",
  },
  {
    where: "privacy.where-local",
    name: setting("reference-size"),
    holds: "privacy.holds-size",
    why: "privacy.why-size",
  },
  {
    where: "privacy.where-local",
    name: setting("way-to-read"),
    holds: "privacy.holds-way",
    why: "privacy.why-way",
  },
  {
    where: "privacy.where-local",
    name: setting("translation"),
    holds: "privacy.holds-translation",
    why: "privacy.why-translation",
  },
  {
    where: "privacy.where-local",
    name: setting("book-names"),
    holds: "privacy.holds-book-names",
    why: "privacy.why-book-names",
  },
  {
    where: "privacy.where-local",
    name: setting("streak"),
    holds: "privacy.holds-days",
    why: "privacy.why-days",
  },
  {
    where: "privacy.where-local",
    name: "dbw.today-ahead",
    holds: "privacy.holds-ahead",
    why: "privacy.why-ahead",
  },
  {
    where: "privacy.where-session",
    name: "dbw.last-action",
    holds: "privacy.holds-last",
    why: "privacy.why-last",
  },
  {
    where: "privacy.where-cache",
    name: "day-by-word-…",
    holds: "privacy.holds-cache",
    why: "privacy.why-cache",
  },
  {
    where: "privacy.where-worker",
    name: "/service-worker.js",
    holds: "privacy.holds-worker",
    why: "privacy.why-worker",
  },
];
