import ReadingEngine
import Testing

/// Plan ids appear in addresses (docs/urls.md), so they are lowercase ASCII
/// letters and digits in words joined by single hyphens.
@Test(arguments: [
    "gospels-at-your-pace", "mcheyne-1842", "psalm-a-day", "a", "2019", String(repeating: "a", count: 64),
])
func acceptsPlanIDs(text: String) throws {
    let id = try #require(PlanID(text))
    #expect(id.rawValue == text)
    #expect(id.description == text)
}

@Test(arguments: [
    "", "-gospels", "gospels-", "gospels--at", "Gospels", "gospels at", "gospels_at", "gospels/at",
    "gospels.at", "évangiles", "ｇospels", String(repeating: "a", count: 65),
])
func refusesOtherText(text: String) {
    #expect(PlanID(text) == nil)
}

@Test func planIDsCompareByText() {
    #expect(PlanID("psalm-a-day") == PlanID("psalm-a-day"))
    #expect(PlanID("psalm-a-day") != PlanID("paul"))
}
