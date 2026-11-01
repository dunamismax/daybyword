import Foundation
import ReadingEngine
import Testing

@testable import DayByWord

private func plan(_ text: String) -> PlanID { PlanID(text)! }

/// Links the app understands, in both forms, and what each one opens. Every
/// row of docs/urls.md's table is here.
@Test(arguments: [
    ("daybyword://today", AppRoute.today),
    ("daybyword://", .today),
    ("daybyword://plans", .plans),
    ("daybyword://plans/", .plans),
    ("daybyword://plans/gospels-at-your-pace", .plan(plan("gospels-at-your-pace"))),
    ("daybyword://plans/psalm-a-day/week", .planWeek(plan("psalm-a-day"), start: nil)),
    ("daybyword://plans/psalm-a-day/week?start=2027-01-04", .planWeek(plan("psalm-a-day"), start: "2027-01-04")),
    ("daybyword://plans/psalm-a-day/week?start=next-week", .planWeek(plan("psalm-a-day"), start: nil)),
    ("daybyword://plans/psalm-a-day/week?start=2027-1-4", .planWeek(plan("psalm-a-day"), start: nil)),
    ("daybyword://progress", .progress),
    ("daybyword://settings", .settings),
    ("DAYBYWORD://plans", .plans),
    ("https://daybyword.com/", .today),
    ("https://daybyword.com/today", .today),
    ("https://daybyword.com/plans", .plans),
    ("https://daybyword.com/plans/mcheyne-1842", .plan(plan("mcheyne-1842"))),
    (
        "https://daybyword.com/plans/mcheyne-1842/week?start=2026-12-28",
        .planWeek(plan("mcheyne-1842"), start: "2026-12-28")
    ),
    ("https://daybyword.com/progress", .progress),
    ("https://daybyword.com/settings", .settings),
    ("https://www.daybyword.com/progress", .progress),
])
func readsLinks(link: String, route: AppRoute) throws {
    #expect(AppRoute(url: try #require(URL(string: link))) == route)
}

/// Anything else is refused, so an unknown link never navigates.
@Test(arguments: [
    "daybyword://nowhere",
    "daybyword://plans/gospels/extra",
    "daybyword://plans/gospels/week/extra",
    "daybyword://plans/Gospels",
    "daybyword://plans/-gospels",
    "daybyword://plans/gospels--1",
    "daybyword://plans/gospels%20one",
    "daybyword://plans/Gospels/week",
    "https://daybyword.org/plans",
    "https://example.com/today",
    "http://daybyword.com/today",
    "youversion://bible?reference=JHN.3.16",
])
func refusesOtherLinks(link: String) throws {
    #expect(AppRoute(url: try #require(URL(string: link))) == nil)
}

/// Every route survives a round trip through its own link and its web address.
@Test(arguments: [
    AppRoute.today, .plans, .plan(plan("psalm-a-day")), .planWeek(plan("psalm-a-day"), start: nil),
    .planWeek(plan("psalm-a-day"), start: "2027-01-04"), .progress, .settings,
])
func routesRoundTrip(route: AppRoute) throws {
    #expect(AppRoute(url: route.url) == route)
    #expect(AppRoute(url: try #require(URL(string: "https://daybyword.com" + route.address))) == route)
}

@MainActor
@Test func openingARouteSelectsItsSectionAndKeepsTheOthers() {
    let navigation = AppNavigation()
    navigation.open(.plan(plan("psalm-a-day")))
    #expect(navigation.selectedTab == .plans)
    #expect(navigation.plansPath == [.plan(plan("psalm-a-day"))])

    navigation.open(.progress)
    #expect(navigation.selectedTab == .progress)
    #expect(navigation.plansPath == [.plan(plan("psalm-a-day"))])

    navigation.open(.settings)
    #expect(navigation.showingSettings)
    #expect(navigation.selectedTab == .progress)

    navigation.open(.today)
    #expect(!navigation.showingSettings)
    #expect(navigation.selectedTab == .today)
}

/// A week opens above its plan's page, so going back reaches the plan.
@MainActor
@Test func aWeekOpensAboveItsPlan() {
    let navigation = AppNavigation()
    navigation.open(.planWeek(plan("paul"), start: "2027-01-04"))
    #expect(navigation.selectedTab == .plans)
    #expect(navigation.plansPath == [.plan(plan("paul")), .planWeek(plan("paul"), start: "2027-01-04")])
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
    navigation.open(.planWeek(plan("paul"), start: nil))
    navigation.selectedTab = .progress

    let restored = AppNavigation()
    restored.restore(from: navigation.encoded)
    #expect(restored.saved == navigation.saved)
    #expect(restored.selectedTab == .progress)
    #expect(restored.plansPath == [.plan(plan("paul")), .planWeek(plan("paul"), start: nil)])
}

@MainActor
@Test func ignoresUnreadableSavedState() {
    let navigation = AppNavigation()
    navigation.restore(from: Data("not json".utf8))
    navigation.restore(
        from: Data(
            #"{"selectedTab":"plans","todayPath":[],"plansPath":[{"plan":{"_0":"Not An Id"}}],"progressPath":[]}"#.utf8)
    )
    navigation.restore(from: Data())
    #expect(navigation.saved == AppNavigation().saved)
    #expect(navigation.selectedTab == .today)
}
