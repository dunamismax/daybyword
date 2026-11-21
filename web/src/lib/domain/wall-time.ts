// A wall-clock time of day (docs/engine.md, "The wire"), as Swift's WallTime
// has it: an hour and a minute with no date and no zone, written `HH:MM`.

export interface WallTime {
  readonly hour: number;
  readonly minute: number;
}

/** A time from `HH:MM`, `00:00` to `23:59` in ASCII digits; undefined for anything else. */
export function parseWallTime(text: string): WallTime | undefined {
  const match = /^([01][0-9]|2[0-3]):([0-5][0-9])$/.exec(text);
  return match ? { hour: Number(match[1]), minute: Number(match[2]) } : undefined;
}

/** `HH:MM`. */
export function wallTimeText(time: WallTime): string {
  const padded = (value: number) => String(value).padStart(2, "0");
  return `${padded(time.hour)}:${padded(time.minute)}`;
}
