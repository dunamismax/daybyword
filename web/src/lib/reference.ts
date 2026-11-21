// A reference as it is shown ("Mark 4:1–20") and as a screen reader reads it
// ("Mark, chapter 4, verses 1 to 20"). The domain module formats the display
// (docs/engine.md); pages only show them.
import { CivilDateError, parseCivilDate } from "#lib/domain/index.ts";

export interface Reference {
  display: string;
  spoken: string;
}

/** The book and the place, so "4:1–20" can be kept on one line. */
export function splitReference(display: string): { book: string; place: string } {
  const space = display.lastIndexOf(" ");
  return space < 0
    ? { book: display, place: "" }
    : { book: display.slice(0, space + 1), place: display.slice(space + 1) };
}

/**
 * A week's start as the address gives it, kept only when it is a date
 * written `YYYY-MM-DD`; anything else, including a date the calendar does
 * not have, is ignored (docs/urls.md).
 */
export function startDate(value: string | null): string | undefined {
  if (value === null) return undefined;
  try {
    parseCivilDate(value);
  } catch (error) {
    if (error instanceof CivilDateError) return undefined;
    throw error;
  }
  return value;
}
