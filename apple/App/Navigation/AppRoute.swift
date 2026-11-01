import Foundation
import ReadingEngine

/// The app's three sections, each a tab with its own navigation stack
/// (docs/product.md, Navigation).
enum AppTab: String, Codable, CaseIterable, Sendable {
    case today
    case plans
    case progress
}

/// A place inside a section's navigation stack.
enum Destination: Hashable, Codable, Sendable {
    case plan(PlanID)
    case planWeek(PlanID, start: String?)
}

/// Every place the app can be sent, by a `daybyword://` link or (later) a
/// daybyword.com universal link (P12.8). The addresses are the web's
/// (docs/urls.md), so `daybyword://plans/psalm-a-day` and
/// `https://daybyword.com/plans/psalm-a-day` name the same place.
enum AppRoute: Hashable, Sendable {
    case today
    case plans
    case plan(PlanID)
    case planWeek(PlanID, start: String?)
    case progress
    case settings

    static let scheme = "daybyword"
    static let webHost = "daybyword.com"

    /// Reads a `daybyword://` link, or an https link on daybyword.com.
    /// Returns nil for anything else, so an unknown link never navigates.
    init?(url: URL) {
        let segments: [String]
        switch url.scheme?.lowercased() {
        case Self.scheme:
            // In `daybyword://plans/psalm-a-day`, "plans" is the URL's host.
            segments = ([url.host(percentEncoded: false)].compactMap { $0 } + url.pathComponents)
                .filter { $0 != "/" && !$0.isEmpty }
        case "https":
            let host = url.host(percentEncoded: false)?.lowercased()
            guard host == Self.webHost || host == "www." + Self.webHost else { return nil }
            segments = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        default:
            return nil
        }
        let start = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "start" }?.value
        self.init(segments: segments, start: start)
    }

    private init?(segments: [String], start: String?) {
        switch (segments.first, segments.count) {
        case (nil, _), ("today", 1): self = .today
        case ("plans", 1): self = .plans
        case ("plans", 2):
            guard let id = PlanID(segments[1]) else { return nil }
            self = .plan(id)
        case ("plans", 3) where segments[2] == "week":
            guard let id = PlanID(segments[1]) else { return nil }
            self = .planWeek(id, start: start.flatMap(Self.startDate))
        case ("progress", 1): self = .progress
        case ("settings", 1): self = .settings
        default: return nil
        }
    }

    /// The route as a `daybyword://` link.
    var url: URL {
        URL(string: "\(Self.scheme)://\(address.dropFirst())")!
    }

    /// The route's address, the same in the app and on the web.
    var address: String {
        switch self {
        case .today: "/today"
        case .plans: "/plans"
        case .plan(let id): "/plans/\(id)"
        case .planWeek(let id, nil): "/plans/\(id)/week"
        case .planWeek(let id, let start?): "/plans/\(id)/week?start=\(start)"
        case .progress: "/progress"
        case .settings: "/settings"
        }
    }

    /// A week's start as the address gives it, kept only when it looks like
    /// `YYYY-MM-DD`; anything else is ignored and the default week shows
    /// (docs/urls.md). `CivilDate` (P5.3) will check that the date exists.
    private static func startDate(_ text: String) -> String? {
        let shape = text.utf8.enumerated().allSatisfy { index, byte in
            index == 4 || index == 7
                ? byte == UInt8(ascii: "-") : (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte)
        }
        return text.utf8.count == 10 && shape ? text : nil
    }
}
