// The edge where an instant becomes a civil date in a time zone
// (docs/engine.md, "Civil dates"), with the cases Swift's CivilDateTests use.
import { describe, expect, it } from "vitest";
import { addDays, CivilDateError, civilDateText, parseCivilDate } from "#lib/domain/index.ts";
import { civilDateIn, deviceZone } from "#lib/today.ts";

const dateIn = (instant: string, zone: string) =>
  civilDateText(civilDateIn(new Date(instant), zone));

describe("today, at the edge", () => {
  it("is a different day in different places at one instant", () => {
    expect(dateIn("2027-03-01T04:30:00Z", "UTC")).toBe("2027-03-01");
    expect(dateIn("2027-03-01T04:30:00Z", "America/New_York")).toBe("2027-02-28");
    expect(dateIn("2027-03-01T04:30:00Z", "Asia/Kolkata")).toBe("2027-03-01");
    expect(dateIn("2027-03-01T11:00:00Z", "Pacific/Kiritimati")).toBe("2027-03-02");
    expect(dateIn("2027-03-01T11:00:00Z", "Pacific/Pago_Pago")).toBe("2027-03-01");
    expect(dateIn("2027-03-01T11:00:00Z", "Etc/GMT+12")).toBe("2027-02-28");
  });

  it("gives midnight to the new day", () => {
    expect(dateIn("2027-03-01T04:59:59Z", "America/New_York")).toBe("2027-02-28");
    expect(dateIn("2027-03-01T05:00:00Z", "America/New_York")).toBe("2027-03-01");
    expect(dateIn("2028-02-29T12:00:00Z", "UTC")).toBe("2028-02-29");
  });

  it("follows daylight saving changes, and a midnight the clocks skip", () => {
    // New York's clocks go forward on 14 March 2027 and back on 7 November.
    expect(dateIn("2027-03-14T04:59:59Z", "America/New_York")).toBe("2027-03-13");
    expect(dateIn("2027-03-14T05:00:00Z", "America/New_York")).toBe("2027-03-14");
    expect(dateIn("2027-03-15T03:59:59Z", "America/New_York")).toBe("2027-03-14");
    expect(dateIn("2027-03-15T04:00:00Z", "America/New_York")).toBe("2027-03-15");
    expect(dateIn("2027-11-08T04:59:59Z", "America/New_York")).toBe("2027-11-07");
    expect(dateIn("2027-11-08T05:00:00Z", "America/New_York")).toBe("2027-11-08");
    // São Paulo skipped midnight on 4 November 2018: the day began at 01:00.
    expect(dateIn("2018-11-04T02:59:59Z", "America/Sao_Paulo")).toBe("2018-11-03");
    expect(dateIn("2018-11-04T03:00:00Z", "America/Sao_Paulo")).toBe("2018-11-04");
  });

  it("agrees with the calendar day by day, whatever the machine's own locale", () => {
    let date = parseCivilDate("2026-01-01");
    for (let day = 0; day < 800; day += 1) {
      const noon = new Date(Date.UTC(date.year, date.month - 1, date.day, 12));
      expect(civilDateText(civilDateIn(noon, "UTC"))).toBe(civilDateText(date));
      date = addDays(date, 1);
    }
  });

  it("refuses a zone that is not one, and a date before year 1", () => {
    expect(() => civilDateIn(new Date("2027-03-01T00:00:00Z"), "Mars/Olympus")).toThrow(RangeError);
    expect(() => civilDateIn(new Date(Date.UTC(-5, 0, 1)), "UTC")).toThrow(CivilDateError);
  });

  it("knows the device's zone by its IANA name", () => {
    expect(deviceZone()).toMatch(/^[A-Za-z_]+(\/[A-Za-z0-9_+-]+)*$/);
  });
});
