import Foundation
import Hummingbird
import HummingbirdTesting
import Testing

@testable import DayByWordWeb

private let mark = Reference(display: "Mark 4:1–20", spoken: "Mark, chapter 4, verses 1 to 20")

@Test func referencesAreReadInTheirSpokenForm() {
    let html = Components.referenceBlock(mark).rendered
    #expect(html.contains(#"<span aria-hidden="true">Mark <span class="nobreak">4:1–20</span></span>"#))
    #expect(html.contains(#"<span class="visually-hidden">Mark, chapter 4, verses 1 to 20</span>"#))
}

@Test(arguments: ReadingStatus.allCases)
func statusesCarryWordsAndSymbols(status: ReadingStatus) {
    let html = Components.assignmentRow(label: "Reading 31", reference: mark, status: status).rendered
    #expect(html.contains(status.label))
    #expect(html.contains(status.symbol))
    #expect(Set(ReadingStatus.allCases.map(\.label)).count == ReadingStatus.allCases.count)
}

@Test func estimatesSayTheyVary() {
    #expect(Components.workload(minutes: 1).rendered.contains("About 1 minute. Estimates vary."))
    #expect(Components.workload(minutes: 12).rendered.contains("About 12 minutes. Estimates vary."))
}

@Test func copyButtonsEscapeTheirText() {
    let html = Components.copyButton(Reference(display: #"Ps 1 "<x>""#, spoken: "")).rendered
    #expect(html.contains(#"data-copy="Ps 1 &quot;&lt;x&gt;&quot;""#))
}

@Test func theGalleryIsServedOnlyInDevelopment() async throws {
    for environment in [ServerConfiguration.Environment.development, .production] {
        var configuration = ServerConfiguration()
        configuration.environment = environment
        configuration.logLevel = .warning
        try await buildApplication(configuration).test(.router) { client in
            try await client.execute(uri: "/dev/components", method: .get) { response in
                #expect(response.status == (environment == .development ? .ok : .notFound))
            }
        }
    }
}
