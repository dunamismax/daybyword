// The edge between instants and civil dates on the web (docs/engine.md,
// "Civil dates"; docs/decisions.md E7), as Swift's CivilDate+Foundation is
// for the app. "Today" is resolved here once, in the reader's time zone, and
// given to the domain module as a civil date; the module itself never sees
// an instant, a clock or a zone.
import { civilDate, type CivilDate } from "#lib/domain/index.ts";

/** The civil date it is at `instant` in the IANA time zone `zone` (for example `America/New_York`). */
export function civilDateIn(instant: Date, zone: string): CivilDate {
  // en-CA with a Gregorian calendar and Latin digits gives plain numeric
  // parts whatever the server's or the browser's own locale is.
  const parts = new Intl.DateTimeFormat("en-CA-u-ca-gregory-nu-latn", {
    timeZone: zone,
    era: "short",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(instant);
  const part = (type: Intl.DateTimeFormatPartTypes) =>
    parts.find((found) => found.type === type)?.value ?? "";
  // Years before 1 are outside the engine's range; civilDate refuses year 0.
  const year = part("era").startsWith("B") ? 0 : Number(part("year"));
  return civilDate(year, Number(part("month")), Number(part("day")));
}

/** The reader's own time zone, as the browser reports it. */
export function deviceZone(): string {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}
