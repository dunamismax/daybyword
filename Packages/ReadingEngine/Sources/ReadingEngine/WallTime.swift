/// A wall-clock time of day (docs/engine.md, "The wire"): an hour and a
/// minute with no date and no zone, written `HH:MM`. Reminders are arranged
/// and answered in wall-clock times, never instants (E40).
public struct WallTime: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let hour: Int
    public let minute: Int

    /// Returns nil unless the hour is 0 to 23 and the minute 0 to 59.
    public init?(hour: Int, minute: Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }

    /// A time from `HH:MM`, `00:00` to `23:59` in ASCII digits; nil for
    /// anything else.
    public init?(_ text: String) {
        let bytes = Array(text.utf8)
        guard bytes.count == 5, bytes[2] == UInt8(ascii: ":") else { return nil }
        var parts: [Int] = []
        for range in [0..<2, 3..<5] {
            var value = 0
            for byte in bytes[range] {
                guard (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte) else { return nil }
                value = value * 10 + Int(byte - UInt8(ascii: "0"))
            }
            parts.append(value)
        }
        self.init(hour: parts[0], minute: parts[1])
    }

    /// `HH:MM`.
    public var description: String {
        func padded(_ value: Int) -> String { value < 10 ? "0\(value)" : "\(value)" }
        return "\(padded(hour)):\(padded(minute))"
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute) }
}
