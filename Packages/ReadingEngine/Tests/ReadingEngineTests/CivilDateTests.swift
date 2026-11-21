import Foundation
import ReadingEngine
import Testing

// Civil dates (docs/engine.md, "Civil dates"): the calendar itself, checked
// against every day the engine handles and against Foundation, and the edge
// where an instant becomes a date in a time zone.

@Test func everyDateFollowsTheOneBefore() throws {
    // Walks 0001-01-01 to 9999-12-31 a day at a time, counting the calendar
    // the long way, and checks each date's number, weekday, and parts.
    var (year, month, day, dayOfYear) = (1, 1, 1, 1)
    let last = CivilDate.latest.ordinal
    #expect(last == 3_652_058)
    for ordinal in 0...last {
        let date = try CivilDate(ordinal: ordinal)
        guard date.year == year, date.month == month, date.day == day, date.ordinal == ordinal,
            date.weekday == ordinal % 7 + 1, date.dayOfYear == dayOfYear
        else {
            Issue.record("day \(ordinal) is \(date), expected \(year)-\(month)-\(day)")
            return
        }
        day += 1
        dayOfYear += 1
        if day > CivilDate.daysInMonth(month, year: year) {
            day = 1
            month += 1
            if month > 12 {
                month = 1
                year += 1
                dayOfYear = 1
            }
        }
    }
    #expect((year, month, day) == (10000, 1, 1))
}

@Test func agreesWithFoundationsGregorianCalendar() throws {
    // Foundation's Gregorian calendar is Julian before October 1582, so the
    // comparison starts after the change.
    var calendar = Calendar(identifier: .gregorian)
    let utc = try #require(TimeZone(identifier: "UTC"))
    calendar.timeZone = utc
    var date = try CivilDate(year: 1583, month: 1, day: 1)
    let end = try CivilDate(year: 2400, month: 12, day: 31)
    var instant = try #require(calendar.date(from: DateComponents(year: 1583, month: 1, day: 1)))
    while date <= end {
        let parts = calendar.dateComponents([.year, .month, .day, .weekday], from: instant)
        // Foundation counts Sunday as 1; ISO counts Monday as 1.
        let weekday = (try #require(parts.weekday) + 5) % 7 + 1
        guard parts.year == date.year, parts.month == date.month, parts.day == date.day, weekday == date.weekday
        else {
            Issue.record("\(date) is weekday \(date.weekday); Foundation says \(parts)")
            return
        }
        #expect(try CivilDate(instant, in: utc) == date)
        date = try date.adding(days: 1)
        instant += 86_400
    }
}

@Test func leapYearsFollowTheGregorianRule() {
    #expect([2024, 2028, 2000, 2400, 4].allSatisfy(CivilDate.isLeapYear))
    #expect(![2027, 1900, 2100, 2200, 1].contains(where: CivilDate.isLeapYear))
    #expect(CivilDate.daysInMonth(2, year: 2028) == 29)
    #expect(CivilDate.daysInMonth(2, year: 2100) == 28)
    #expect((1...12).map { CivilDate.daysInMonth($0, year: 2027) } == [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31])
}

@Test func readsAndWritesYearMonthDay() throws {
    let date = try CivilDate("2027-03-01")
    #expect((date.year, date.month, date.day) == (2027, 3, 1))
    #expect(date.description == "2027-03-01")
    #expect(date.weekday == 1)
    #expect(try CivilDate("0033-04-05").description == "0033-04-05")
    #expect(try CivilDate(year: 2028, month: 2, day: 29).dayOfYear == 60)
    #expect(try CivilDate("2027-12-31").dayOfYear == 365)
    #expect(try CivilDate("2028-12-31").dayOfYear == 366)
    #expect(try CivilDate("2027-02-10").daysInMonth == 28)
}

@Test(arguments: [
    "", "2027-1-4", "2027/01/04", "20270104", "2027-01-04 ", " 2027-01-04", "2027-01-04T00:00:00Z", "+027-01-04",
    "２０２７-01-04", "2027-01-0４", "27-01-04", "2027-01-4a", "2027–01–04",
])
func refusesTextThatIsNotADate(text: String) {
    #expect(throws: CivilDateError.malformed(text)) { try CivilDate(text) }
}

@Test(arguments: ["2027-02-29", "2027-02-30", "2100-02-29", "2027-04-31", "2027-13-01", "2027-00-10", "2027-01-00"])
func refusesDatesTheCalendarLacks(text: String) {
    #expect(throws: CivilDateError.noSuchDate(text)) { try CivilDate(text) }
}

@Test func staysInsideItsRange() throws {
    #expect(throws: CivilDateError.outOfRange) { try CivilDate("0000-12-31") }
    #expect(throws: CivilDateError.outOfRange) { try CivilDate(year: 10000, month: 1, day: 1) }
    #expect(throws: CivilDateError.outOfRange) { try CivilDate(year: 0, month: 1, day: 1) }
    #expect(throws: CivilDateError.outOfRange) { try CivilDate.earliest.adding(days: -1) }
    #expect(throws: CivilDateError.outOfRange) { try CivilDate.latest.adding(days: 1) }
    #expect(throws: CivilDateError.outOfRange) { try CivilDate.latest.adding(days: .max) }
    #expect(throws: CivilDateError.outOfRange) { try CivilDate(ordinal: -1) }
    #expect(try CivilDate.earliest.adding(days: 3_652_058) == CivilDate.latest)
    #expect(CivilDate.earliest.description == "0001-01-01")
    #expect(CivilDate.earliest.weekday == 1)
}

@Test func addsAndCountsWholeDays() throws {
    #expect(try CivilDate("2027-02-28").adding(days: 1) == CivilDate("2027-03-01"))
    #expect(try CivilDate("2028-02-28").adding(days: 1) == CivilDate("2028-02-29"))
    #expect(try CivilDate("2027-03-01").adding(days: -1) == CivilDate("2027-02-28"))
    #expect(try CivilDate("2027-12-31").adding(days: 1) == CivilDate("2028-01-01"))
    #expect(try CivilDate("2027-12-25").days(to: CivilDate("2028-01-01")) == 7)
    #expect(try CivilDate("2028-01-01").days(to: CivilDate("2027-12-25")) == -7)
    #expect(try CivilDate("2027-03-01") < CivilDate("2027-03-02"))
    #expect(try CivilDate("2026-12-31") < CivilDate("2027-01-01"))
}

@Test func codesAsText() throws {
    let date = try CivilDate("2027-03-01")
    #expect(String(decoding: try JSONEncoder().encode([date]), as: UTF8.self) == #"["2027-03-01"]"#)
    #expect(try JSONDecoder().decode([CivilDate].self, from: Data(#"["2027-03-01"]"#.utf8)) == [date])
    #expect(throws: DecodingError.self) {
        try JSONDecoder().decode([CivilDate].self, from: Data(#"["2027-02-30"]"#.utf8))
    }
}

// MARK: The edge

private func instant(_ text: String) throws -> Date {
    try #require(ISO8601DateFormatter().date(from: text))
}

private func zone(_ name: String) throws -> TimeZone { try #require(TimeZone(identifier: name)) }

@Test func anInstantIsADifferentDayInDifferentPlaces() throws {
    // Half past four in the morning in Greenwich on 1 March.
    let moment = try instant("2027-03-01T04:30:00Z")
    #expect(try CivilDate(moment, in: zone("UTC")) == CivilDate("2027-03-01"))
    #expect(try CivilDate(moment, in: zone("America/New_York")) == CivilDate("2027-02-28"))
    #expect(try CivilDate(moment, in: zone("Asia/Kolkata")) == CivilDate("2027-03-01"))
    // Across the date line: the same instant is two dates apart at the extremes.
    let noon = try instant("2027-03-01T11:00:00Z")
    #expect(try CivilDate(noon, in: zone("Pacific/Kiritimati")) == CivilDate("2027-03-02"))
    #expect(try CivilDate(noon, in: zone("Pacific/Pago_Pago")) == CivilDate("2027-03-01"))
    #expect(try CivilDate(noon, in: zone("Etc/GMT+12")) == CivilDate("2027-02-28"))
}

@Test func midnightBelongsToTheNewDay() throws {
    let newYork = try zone("America/New_York")
    #expect(try CivilDate(instant("2027-03-01T04:59:59Z"), in: newYork) == CivilDate("2027-02-28"))
    #expect(try CivilDate(instant("2027-03-01T05:00:00Z"), in: newYork) == CivilDate("2027-03-01"))
    // Leap day.
    #expect(try CivilDate(instant("2028-02-29T12:00:00Z"), in: zone("UTC")) == CivilDate("2028-02-29"))
}

@Test func aDayStartsAtItsFirstInstant() throws {
    let newYork = try zone("America/New_York")
    #expect(try CivilDate("2027-03-01").start(in: newYork) == instant("2027-03-01T05:00:00Z"))
    // Clocks go forward on 14 March 2027 and back on 7 November: the days are
    // 23 and 25 hours long, and each still starts at its own midnight.
    let spring = try CivilDate("2027-03-14")
    let springNext = try spring.adding(days: 1)
    #expect(springNext.start(in: newYork).timeIntervalSince(spring.start(in: newYork)) == 23 * 3600)
    let autumn = try CivilDate("2027-11-07")
    let autumnNext = try autumn.adding(days: 1)
    #expect(autumnNext.start(in: newYork).timeIntervalSince(autumn.start(in: newYork)) == 25 * 3600)
    // São Paulo's clocks skipped midnight on 4 November 2018: the day began at 01:00.
    let saoPaulo = try zone("America/Sao_Paulo")
    let skipped = try CivilDate("2018-11-04")
    #expect(skipped.start(in: saoPaulo) == (try instant("2018-11-04T03:00:00Z")))
    #expect(try CivilDate(skipped.start(in: saoPaulo), in: saoPaulo) == skipped)
    #expect(try CivilDate(skipped.start(in: saoPaulo) - 1, in: saoPaulo) == skipped.adding(days: -1))
}

@Test func everyDaysStartIsInThatDay() throws {
    for name in ["America/New_York", "Europe/London", "Australia/Lord_Howe", "Asia/Kathmandu", "Pacific/Apia"] {
        let zone = try zone(name)
        var date = try CivilDate("2026-01-01")
        for _ in 0..<800 {
            let start = date.start(in: zone)
            #expect(try CivilDate(start, in: zone) == date, "\(name) \(date)")
            #expect(try CivilDate(start - 1, in: zone) == date.adding(days: -1), "\(name) \(date)")
            date = try date.adding(days: 1)
        }
    }
}

// MARK: The edge for reminders

@Test func anInstantIsADifferentWallClockTimeInDifferentPlaces() throws {
    // 13:30 UTC on 12 March 2027: 07:30 in Chicago, 22:30 in Tokyo, and
    // 03:30 in Honolulu.
    let moment = try instant("2027-03-12T13:30:00Z")
    let chicago = try LocalDateTime(moment, in: zone("America/Chicago"))
    #expect(chicago.date.description == "2027-03-12" && chicago.time.description == "07:30")
    let tokyo = try LocalDateTime(moment, in: zone("Asia/Tokyo"))
    #expect(tokyo.date.description == "2027-03-12" && tokyo.time.description == "22:30")
    let honolulu = try LocalDateTime(moment, in: zone("Pacific/Honolulu"))
    #expect(honolulu.date.description == "2027-03-12" && honolulu.time.description == "03:30")
    // Across the date line the same instant is another date.
    let auckland = try LocalDateTime(moment, in: zone("Pacific/Auckland"))
    #expect(auckland.date.description == "2027-03-13" && auckland.time.description == "02:30")
    #expect(chicago < tokyo && tokyo < auckland)
}

@Test func theWallClockSkipsAndRepeatsAnHourWhenTheClocksChange() throws {
    let chicago = try zone("America/Chicago")
    // The clocks go forward on 14 March 2027: 01:59 is followed by 03:00.
    let before = try LocalDateTime(instant("2027-03-14T07:59:00Z"), in: chicago)
    let after = try LocalDateTime(instant("2027-03-14T08:00:00Z"), in: chicago)
    #expect(before.time.description == "01:59" && after.time.description == "03:00")
    // They go back on 7 November 2027: 01:30 happens twice.
    let first = try LocalDateTime(instant("2027-11-07T06:30:00Z"), in: chicago)
    let second = try LocalDateTime(instant("2027-11-07T07:30:00Z"), in: chicago)
    #expect(first == second && first.time.description == "01:30")
}

@Test func aReminderKeepsItsWallClockTimeAcrossAClockChange() throws {
    // A calendar in the device's zone turns the engine's wall-clock answer
    // into the instant the system fires at: 07:00 the day before, the day
    // of, and the day after the clocks go forward, 24, 23 and 24 hours apart.
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try zone("America/Chicago")
    let time = try #require(WallTime("07:00"))
    let fires = try ["2027-03-13", "2027-03-14", "2027-03-15"].map {
        try #require(calendar.date(from: LocalDateTime(date: try CivilDate($0), time: time).components))
    }
    #expect(fires[0] == (try instant("2027-03-13T13:00:00Z")))
    #expect(fires[1].timeIntervalSince(fires[0]) == 23 * 3600)
    #expect(fires[2].timeIntervalSince(fires[1]) == 24 * 3600)
    for fire in fires { #expect(try LocalDateTime(fire, in: calendar.timeZone).time == time) }

    // 02:30 does not exist on 14 March; the next minute that does is 03:00.
    let skipped = LocalDateTime(date: try CivilDate("2027-03-14"), time: try #require(WallTime("02:30")))
    let next = try #require(
        calendar.nextDate(
            after: try instant("2027-03-14T06:00:00Z"), matching: skipped.components, matchingPolicy: .nextTime))
    #expect(try LocalDateTime(next, in: calendar.timeZone).time.description == "03:00")
}
