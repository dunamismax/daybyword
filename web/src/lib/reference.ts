// A reference as it is shown ("Mark 4:1–20") and as a screen reader reads it
// ("Mark, chapter 4, verses 1 to 20"). The domain module formats the display
// (docs/engine.md); pages only show them.
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
 * A week's start as the address gives it, kept only when it looks like
 * `YYYY-MM-DD`; anything else is ignored (docs/urls.md). CivilDate (P5.3)
 * will check that the date exists.
 */
export function startDate(value: string | null): string | undefined {
  return value !== null && /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/.test(value) ? value : undefined;
}
