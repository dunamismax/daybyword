// A calendar file of the readings ahead (BUILD.md P13.4, docs/decisions.md
// E59): iCalendar (RFC 5545) text the reader imports into their own
// calendar. A snapshot, not a subscription: the readings come from the
// engine's days ahead, and the file says nothing the reader did not choose.
// The app writes the same bytes (apple/App/Model/CalendarFile.swift), held
// to tests/fixtures/calendar.json.

/** One day's readings in one plan. */
export interface CalendarEvent {
  /** The enrollment's id, which with the date makes the event's UID. */
  readonly enrollment: string;
  /** A civil date, YYYY-MM-DD. */
  readonly date: string;
  readonly plan: string;
  /** "Reading 12", or "Day 21" by the date. */
  readonly label: string;
  /** The day's references as shown ("Matthew 1–3"). */
  readonly references: readonly string[];
}

export interface CalendarOptions {
  /** The moment the file is made, as an ISO 8601 instant in UTC. */
  readonly stamp: string;
  /** A wall-clock time HH:MM for each event, or all-day when absent. */
  readonly time?: string;
  /** The description, from the string table, with {label} in it. */
  readonly description: string;
}

/** The calendar file for `events`, lines joined by CRLF. */
export function calendarFile(events: readonly CalendarEvent[], options: CalendarOptions): string {
  const stamp = options.stamp.replace(/[-:]/g, "").replace(/\.\d+/, "");
  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Day by Word//Calendar export 1//EN",
    "CALSCALE:GREGORIAN",
  ];
  for (const event of events) {
    const day = event.date.replaceAll("-", "");
    lines.push("BEGIN:VEVENT", `UID:${event.enrollment}-${day}@daybyword.com`, `DTSTAMP:${stamp}`);
    if (options.time === undefined) {
      lines.push(`DTSTART;VALUE=DATE:${day}`, `DTEND;VALUE=DATE:${nextDay(event.date)}`);
    } else {
      // Floating time: the wall-clock time wherever the reader is, as the
      // reminders are (docs/engine.md, "Reminders").
      lines.push(`DTSTART:${day}T${options.time.replace(":", "")}00`, "DURATION:PT15M");
    }
    lines.push(
      `SUMMARY:${escape(`${event.plan}: ${event.references.join("; ")}`)}`,
      `DESCRIPTION:${escape(options.description.replace("{label}", event.label))}`,
      "TRANSP:TRANSPARENT",
      "END:VEVENT",
    );
  }
  lines.push("END:VCALENDAR");
  return lines.map(fold).join("\r\n") + "\r\n";
}

/** The day after a civil date, YYYYMMDD. */
function nextDay(date: string): string {
  const [year, month, day] = date.split("-").map(Number) as [number, number, number];
  const next = new Date(Date.UTC(year, month - 1, day + 1));
  return next.toISOString().slice(0, 10).replaceAll("-", "");
}

/** RFC 5545 TEXT: backslash, semicolon, comma and newline escaped. */
function escape(text: string): string {
  return text
    .replaceAll("\\", "\\\\")
    .replaceAll(";", "\\;")
    .replaceAll(",", "\\,")
    .replaceAll("\n", "\\n");
}

/** A line of at most 75 octets, continued on lines that begin with a
 * space, never splitting a character. */
function fold(line: string): string {
  const encoder = new TextEncoder();
  const parts: string[] = [];
  let current = "";
  let octets = 0;
  for (const character of line) {
    const size = encoder.encode(character).length;
    const limit = parts.length === 0 ? 75 : 74;
    if (octets + size > limit) {
      parts.push(current);
      current = "";
      octets = 0;
    }
    current += character;
    octets += size;
  }
  parts.push(current);
  return parts.join("\r\n ");
}
