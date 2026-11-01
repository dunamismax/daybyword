import Foundation
import Testing

@testable import DayByWord

/// Links the app understands, in both forms, and what each one opens.
@Test(arguments: [
    ("daybyword://today", AppRoute.today),
    ("daybyword://", .today),
    ("daybyword://plans", .plans),
    ("daybyword://plans/", .plans),
    ("daybyword://plans/gospels-at-your-pace", .plan(id: "gospels-at-your-pace")),
    ("daybyword://progress", .progress),
    ("daybyword://settings", .settings),
    ("DAYBYWORD://plans", .plans),
    ("https://daybyword.com/", .today),
    ("https://daybyword.com/today", .today),
    ("https://daybyword.com/plans/mcheyne-1842", .plan(id: "mcheyne-1842")),
    ("https://www.daybyword.com/progress", .progress),
])
func readsLinks(link: String, route: AppRoute) throws {
    #expect(AppRoute(url: try #require(URL(string: link))) == route)
}

/// Anything else is refused, so an unknown link never navigates.
@Test(arguments: [
    "daybyword://nowhere",
    "daybyword://plans/gospels/extra",
    "daybyword://plans/Gospels",
    "daybyword://plans/-gospels",
    "daybyword://plans/gospels--1",
    "daybyword://plans/gospels%20one",
    "https://daybyword.org/plans",
    "https://example.com/today",
    "http://daybyword.com/today",
    "youversion://bible?reference=JHN.3.16",
])
func refusesOtherLinks(link: String) throws {
    #expect(AppRoute(url: try #require(URL(string: link))) == nil)
}

/// Every route survives a round trip through its own link and its web path.
@Test(arguments: [AppRoute.today, .plans, .plan(id: "psalm-a-day"), .progress, .settings])
func routesRoundTrip(route: AppRoute) throws {
    #expect(AppRoute(url: route.url) == route)
    #expect(AppRoute(url: try #require(URL(string: "https://daybyword.com" + route.path))) == route)
}

@MainActor
@Test func openingARouteSelectsItsSectionAndKeepsTheOthers() {
    let navigation = AppNavigation()
    navigation.open(.plan(id: "psalm-a-day"))
    #expect(navigation.selectedTab == .plans)
    #expect(navigation.plansPath == [.plan(id: "psalm-a-day")])

    navigation.open(.progress)
    #expect(navigation.selectedTab == .progress)
    #expect(navigation.plansPath == [.plan(id: "psalm-a-day")])

    navigation.open(.settings)
    #expect(navigation.showingSettings)
    #expect(navigation.selectedTab == .progress)

    navigation.open(.today)
    #expect(!navigation.showingSettings)
    #expect(navigation.selectedTab == .today)
}

@MainActor
@Test func unknownLinksChangeNothing() throws {
    let navigation = AppNavigation()
    navigation.open(.plans)
    #expect(!navigation.open(try #require(URL(string: "daybyword://nowhere"))))
    #expect(navigation.selectedTab == .plans)
}

@MainActor
@Test func restoresTheSavedPlace() {
    let navigation = AppNavigation()
    navigation.open(.plan(id: "paul"))
    navigation.selectedTab = .progress

    let restored = AppNavigation()
    restored.restore(from: navigation.encoded)
    #expect(restored.saved == navigation.saved)
    #expect(restored.selectedTab == .progress)
    #expect(restored.plansPath == [.plan(id: "paul")])
}

@MainActor
@Test func ignoresUnreadableSavedState() {
    let navigation = AppNavigation()
    navigation.restore(from: Data("not json".utf8))
    navigation.restore(from: Data())
    #expect(navigation.saved == AppNavigation().saved)
    #expect(navigation.selectedTab == .today)
}
