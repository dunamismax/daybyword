// The calendar file against tests/fixtures/calendar.json (BUILD.md P13.4,
// docs/decisions.md E59). The app's writer is held to the same cases in
// apple/AppTests/CalendarFileTests.swift.
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { calendarFile, type CalendarEvent } from "#lib/calendar.ts";
import { text } from "#lib/strings.ts";

interface Case {
  name: string;
  stamp: string;
  time?: string;
  events: CalendarEvent[];
  lines: string[];
}

const fixture = JSON.parse(
  readFileSync(new URL("../../tests/fixtures/calendar.json", import.meta.url), "utf8"),
) as { description: string; cases: Case[] };

describe("the calendar file", () => {
  it("uses the string table's description", () => {
    expect(text("calendar.description")).toBe(fixture.description);
  });

  for (const item of fixture.cases) {
    it(item.name, () => {
      const file = calendarFile(item.events, {
        stamp: item.stamp,
        ...(item.time === undefined ? {} : { time: item.time }),
        description: fixture.description,
      });
      expect(file).toBe(item.lines.join("\r\n") + "\r\n");
      for (const line of file.split("\r\n")) {
        expect(new TextEncoder().encode(line).length).toBeLessThanOrEqual(75);
      }
    });
  }
});
