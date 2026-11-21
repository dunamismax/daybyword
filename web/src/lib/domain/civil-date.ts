// Civil dates (docs/engine.md, "Civil dates"; docs/decisions.md E7), as
// Swift's CivilDate has them: a year, month and day in the proleptic
// Gregorian calendar, with no time and no zone. An instant becomes a civil
// date once, at the edge (src/lib/today.ts), never here.

export type CivilDateErrorKind = "malformed" | "noSuchDate" | "outOfRange";

export class CivilDateError extends Error {
  override name = "CivilDateError";
  readonly kind: CivilDateErrorKind;
  constructor(kind: CivilDateErrorKind, message: string) {
    super(message);
    this.kind = kind;
  }
}

export interface CivilDate {
  readonly year: number;
  readonly month: number;
  readonly day: number;
}

const outOfRange = () =>
  new CivilDateError("outOfRange", "the date is outside 0001-01-01 to 9999-12-31");

/** Divisible by 4, except centuries not divisible by 400. */
export function isLeapYear(year: number): boolean {
  return year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
}

const monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

export function daysInMonth(month: number, year: number): number {
  return month === 2 && isLeapYear(year) ? 29 : (monthLengths[month - 1] as number);
}

/** `YYYY-MM-DD`. */
export function civilDateText(date: CivilDate): string {
  const padded = (value: number, width: number) => String(value).padStart(width, "0");
  return `${padded(date.year, 4)}-${padded(date.month, 2)}-${padded(date.day, 2)}`;
}

/** A date from its parts, refusing a year outside 1 to 9999 and a day the month does not have. */
export function civilDate(year: number, month: number, day: number): CivilDate {
  if (![year, month, day].every(Number.isInteger)) throw outOfRange();
  if (year < 1 || year > 9999) throw outOfRange();
  if (month < 1 || month > 12 || day < 1 || day > daysInMonth(month, year)) {
    throw new CivilDateError(
      "noSuchDate",
      `there is no such date as ${civilDateText({ year, month, day })}`,
    );
  }
  return { year, month, day };
}

/** A date from `YYYY-MM-DD`: four, two and two ASCII digits, and nothing else. */
export function parseCivilDate(text: string): CivilDate {
  const match = /^([0-9]{4})-([0-9]{2})-([0-9]{2})$/.exec(text);
  if (!match) {
    throw new CivilDateError("malformed", `"${text}" is not a date written YYYY-MM-DD`);
  }
  const [year, month, day] = [Number(match[1]), Number(match[2]), Number(match[3])];
  // Year 0000 is well formed but before the first date.
  if (year < 1) throw outOfRange();
  if (month < 1 || month > 12 || day < 1 || day > daysInMonth(month, year)) {
    throw new CivilDateError("noSuchDate", `there is no such date as ${text}`);
  }
  return { year, month, day };
}

/** The day of the year, from 1. */
export function dayOfYear(date: CivilDate): number {
  let days = date.day;
  for (let month = 1; month < date.month; month += 1) days += daysInMonth(month, date.year);
  return days;
}

/** The whole days since 0001-01-01, which is 0. */
export function ordinal(date: CivilDate): number {
  const before = date.year - 1;
  return (
    before * 365 +
    Math.floor(before / 4) -
    Math.floor(before / 100) +
    Math.floor(before / 400) +
    dayOfYear(date) -
    1
  );
}

const latestOrdinal = ordinal({ year: 9999, month: 12, day: 31 });

/** The date a number of days after 0001-01-01. */
export function civilDateFromOrdinal(value: number): CivilDate {
  if (!Number.isInteger(value) || value < 0 || value > latestOrdinal) throw outOfRange();
  // 400 years are 146,097 days, a century 36,524 (the fourth has one more),
  // four years 1,461, and a year 365 (the fourth has one more).
  let days = value;
  const eras = Math.floor(days / 146_097);
  days %= 146_097;
  const centuries = Math.min(Math.floor(days / 36_524), 3);
  days -= centuries * 36_524;
  const fours = Math.floor(days / 1_461);
  days %= 1_461;
  const years = Math.min(Math.floor(days / 365), 3);
  days -= years * 365;
  const year = eras * 400 + centuries * 100 + fours * 4 + years + 1;
  let month = 1;
  while (days >= daysInMonth(month, year)) {
    days -= daysInMonth(month, year);
    month += 1;
  }
  return { year, month, day: days + 1 };
}

/** The weekday as ISO 8601 numbers it: 1 is Monday and 7 is Sunday. */
export function weekday(date: CivilDate): number {
  return (ordinal(date) % 7) + 1;
}

/** The date `days` later, or earlier when negative. */
export function addDays(date: CivilDate, days: number): CivilDate {
  if (!Number.isInteger(days)) throw outOfRange();
  return civilDateFromOrdinal(ordinal(date) + days);
}

/** The whole days from `from` to `to`, negative when `to` is earlier. */
export function daysBetween(from: CivilDate, to: CivilDate): number {
  return ordinal(to) - ordinal(from);
}

/** Negative, zero or positive as `a` is before, the same as, or after `b`. */
export function compareCivilDates(a: CivilDate, b: CivilDate): number {
  return ordinal(a) - ordinal(b);
}
