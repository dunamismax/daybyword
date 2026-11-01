import Foundation
import Observation

/// Where the reader is: the selected section, the place within each section,
/// and whether Settings is open. The scene saves it and restores it when the
/// system relaunches the app (docs/decisions.md E24).
@MainActor
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .today
    var todayPath: [Destination] = []
    var plansPath: [Destination] = []
    var progressPath: [Destination] = []
    var showingSettings = false

    init() {}

    /// Goes to a route: selects its section, sets that section's path, and
    /// leaves the other sections where they were.
    func open(_ route: AppRoute) {
        showingSettings = false
        switch route {
        case .today:
            selectedTab = .today
            todayPath = []
        case .plans:
            selectedTab = .plans
            plansPath = []
        case .plan(let id):
            selectedTab = .plans
            plansPath = [.plan(id: id)]
        case .progress:
            selectedTab = .progress
            progressPath = []
        case .settings:
            showingSettings = true
        }
    }

    /// Opens a link, and reports whether the app understood it.
    @discardableResult
    func open(_ url: URL) -> Bool {
        guard let route = AppRoute(url: url) else { return false }
        open(route)
        return true
    }

    // MARK: Saving and restoring

    struct Saved: Codable, Equatable {
        var selectedTab: AppTab
        var todayPath: [Destination]
        var plansPath: [Destination]
        var progressPath: [Destination]
    }

    var saved: Saved {
        Saved(selectedTab: selectedTab, todayPath: todayPath, plansPath: plansPath, progressPath: progressPath)
    }

    /// The saved state as data for scene storage.
    var encoded: Data {
        (try? JSONEncoder().encode(saved)) ?? Data()
    }

    /// Restores a saved state. Data that cannot be read (from an older
    /// version, say) is ignored, and the reader starts on Today.
    func restore(from data: Data) {
        guard let saved = try? JSONDecoder().decode(Saved.self, from: data) else { return }
        selectedTab = saved.selectedTab
        todayPath = saved.todayPath
        plansPath = saved.plansPath
        progressPath = saved.progressPath
    }
}
