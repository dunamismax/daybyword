/// A day on the calendar: a year, month, and day in the proleptic Gregorian
/// calendar, with no time and no zone (docs/engine.md, "Civil dates";
/// docs/decisions.md E7). Plans, enrollments, and the journal speak in civil
/// dates; an instant becomes one once, at the edge, in the reader's time
/// zone (`CivilDate+Foundation.swift`), so a reading day is never an instant.
/// Written fresh for Day by Word (D22).
public struct CivilDate: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    /// The first and last dates the engine handles.
    public static let earliest = CivilDate(unchecked: 1, 1, 1)
    public static let latest = CivilDate(unchecked: 9999, 12, 31)

    private init(unchecked year: Int, _ month: Int, _ day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// A date from its parts, refusing a year outside 1 to 9999 and a day the
    /// month does not have.
    public init(year: Int, month: Int, day: Int) throws(CivilDateError) {
        guard (1...9999).contains(year) else { throw .outOfRange }
        guard (1...12).contains(month), (1...Self.daysInMonth(month, year: year)).contains(day) else {
            throw .noSuchDate(Self.text(year, month, day))
        }
        self.init(unchecked: year, month, day)
    }

    /// A date from `YYYY-MM-DD`: four, two, and two ASCII digits, and nothing
    /// else.
    public init(_ text: String) throws(CivilDateError) {
        let bytes = Array(text.utf8)
        guard bytes.count == 10, bytes[4] == hyphen, bytes[7] == hyphen else { throw .malformed(text) }
        func number(_ range: Range<Int>) -> Int? {
            var value = 0
            for byte in bytes[range] {
                guard (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte) else { return nil }
                value = value * 10 + Int(byte - UInt8(ascii: "0"))
            }
            return value
        }
        guard let year = number(0..<4), let month = number(5..<7), let day = number(8..<10) else {
            throw .malformed(text)
        }
        // Year 0000 is well formed but before the first date.
        guard year >= 1 else { throw .outOfRange }
        guard (1...12).contains(month), (1...Self.daysInMonth(month, year: year)).contains(day) else {
            throw .noSuchDate(text)
        }
        self.init(unchecked: year, month, day)
    }

    /// `YYYY-MM-DD`.
    public var description: String { Self.text(year, month, day) }

    private static func text(_ year: Int, _ month: Int, _ day: Int) -> String {
        func padded(_ value: Int, _ width: Int) -> String {
            let digits = String(value)
            return String(repeating: "0", count: max(0, width - digits.count)) + digits
        }
        return "\(padded(year, 4))-\(padded(month, 2))-\(padded(day, 2))"
    }

    // MARK: The calendar

    /// Divisible by 4, except centuries not divisible by 400.
    public static func isLeapYear(_ year: Int) -> Bool {
        year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
    }

    public static func daysInMonth(_ month: Int, year: Int) -> Int {
        month == 2 && isLeapYear(year) ? 29 : monthLengths[month - 1]
    }

    private static let monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    /// The days in this date's month.
    public var daysInMonth: Int { Self.daysInMonth(month, year: year) }

    /// The day of the year, from 1.
    public var dayOfYear: Int {
        (1..<month).reduce(day) { $0 + Self.daysInMonth($1, year: year) }
    }

    /// The whole days since 0001-01-01, which is 0.
    public var ordinal: Int {
        let before = year - 1
        return before * 365 + before / 4 - before / 100 + before / 400 + dayOfYear - 1
    }

    /// The date a number of days after 0001-01-01.
    public init(ordinal: Int) throws(CivilDateError) {
        guard (0...Self.latest.ordinal).contains(ordinal) else { throw .outOfRange }
        // 400 years are 146,097 days, a century 36,524 (the fourth has one
        // more), four years 1,461, and a year 365 (the fourth has one more).
        var days = ordinal
        let eras = days / 146_097
        days %= 146_097
        let centuries = min(days / 36_524, 3)
        days -= centuries * 36_524
        let fours = days / 1_461
        days %= 1_461
        let years = min(days / 365, 3)
        days -= years * 365
        let year = eras * 400 + centuries * 100 + fours * 4 + years + 1
        var month = 1
        while days >= Self.daysInMonth(month, year: year) {
            days -= Self.daysInMonth(month, year: year)
            month += 1
        }
        self.init(unchecked: year, month, days + 1)
    }

    /// The weekday as ISO 8601 numbers it: 1 is Monday and 7 is Sunday.
    /// 0001-01-01 is a Monday.
    public var weekday: Int { ordinal % 7 + 1 }

    // MARK: Arithmetic

    /// The date `days` later, or earlier when negative.
    public func adding(days: Int) throws(CivilDateError) -> CivilDate {
        let (sum, overflow) = ordinal.addingReportingOverflow(days)
        guard !overflow else { throw .outOfRange }
        return try CivilDate(ordinal: sum)
    }

    /// The whole days from this date to `other`, negative when it is earlier.
    public func days(to other: CivilDate) -> Int { other.ordinal - ordinal }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    // MARK: Coding

    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        do throws(CivilDateError) {
            self = try CivilDate(text)
        } catch {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: error.description))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

private let hyphen = UInt8(ascii: "-")

/// Why text or numbers are not a civil date (docs/engine.md). The kind is the
/// contract; the message is for plan authors and logs.
public enum CivilDateError: Error, Hashable, Sendable, CustomStringConvertible {
    /// Not `YYYY-MM-DD`.
    case malformed(String)
    /// Well formed, but the month has no such day, or there is no such month.
    case noSuchDate(String)
    /// Before 0001-01-01 or after 9999-12-31.
    case outOfRange

    public var kind: String {
        switch self {
        case .malformed: "malformed"
        case .noSuchDate: "noSuchDate"
        case .outOfRange: "outOfRange"
        }
    }

    public var description: String {
        switch self {
        case .malformed(let text): "\"\(text)\" is not a date written YYYY-MM-DD"
        case .noSuchDate(let text): "there is no such date as \(text)"
        case .outOfRange: "the date is outside 0001-01-01 to 9999-12-31"
        }
    }
}
