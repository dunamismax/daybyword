import Foundation

/// The app's three sections, each a tab with its own navigation stack
/// (docs/product.md, Navigation).
enum AppTab: String, Codable, CaseIterable, Sendable {
    case today
    case plans
    case progress
}

/// A place inside a section's navigation stack.
enum Destination: Hashable, Codable, Sendable {
    case plan(id: String)
}

/// Every place the app can be sent, by a `daybyword://` link or (later) a
/// daybyword.com universal link (P12.8). The paths mirror the web's URLs
/// (docs/urls.md), so `daybyword://plans/gospels` and
/// `https://daybyword.com/plans/gospels` name the same place.
enum AppRoute: Hashable, Sendable {
    case today
    case plans
    case plan(id: String)
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
            // In `daybyword://plans/gospels`, "plans" is the URL's host.
            segments = ([url.host(percentEncoded: false)].compactMap { $0 } + url.pathComponents)
                .filter { $0 != "/" && !$0.isEmpty }
        case "https":
            let host = url.host(percentEncoded: false)?.lowercased()
            guard host == Self.webHost || host == "www." + Self.webHost else { return nil }
            segments = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        default:
            return nil
        }
        self.init(segments: segments)
    }

    private init?(segments: [String]) {
        switch (segments.first, segments.count) {
        case (nil, _), ("today", 1): self = .today
        case ("plans", 1): self = .plans
        case ("plans", 2) where Self.isPlanID(segments[1]): self = .plan(id: segments[1])
        case ("progress", 1): self = .progress
        case ("settings", 1): self = .settings
        default: return nil
        }
    }

    /// The route as a `daybyword://` link.
    var url: URL {
        URL(string: "\(Self.scheme)://\(path.dropFirst())")!
    }

    /// The route's path, the same in the app and on the web.
    var path: String {
        switch self {
        case .today: "/today"
        case .plans: "/plans"
        case .plan(let id): "/plans/\(id)"
        case .progress: "/progress"
        case .settings: "/settings"
        }
    }

    /// Plan ids are lowercase letters, digits, and single hyphens, until the
    /// catalog format (P4.2) states its own rule.
    static func isPlanID(_ id: String) -> Bool {
        !id.isEmpty && id.count <= 64 && !id.hasPrefix("-") && !id.hasSuffix("-") && !id.contains("--")
            && id.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == "-" }
    }
}
