import Foundation
import Hummingbird
import HummingbirdTesting
import Testing

@testable import DayByWordWeb

/// Every key has English text, and every placeholder is named.
@Test(arguments: StringKey.allCases)
func everyKeyHasEnglish(key: StringKey) throws {
    let english = try #require(Strings.english.table[key])
    #expect(!english.trimmingCharacters(in: .whitespaces).isEmpty)
    #expect(english.trimmingCharacters(in: .whitespaces) == english)
    #expect(!english.contains("{}"))
}

@Test func placeholdersAreFilled() {
    #expect(text(.workloadOther, ["minutes": "12"]) == "About 12 minutes. Estimates vary.")
    #expect(text(.pageTitle, ["page": "Plans"]) == "Plans · Day by Word")
}

/// The words a page shows: text between tags, and the attributes a reader
/// meets (titles, labels, and the copy button's messages).
private func readerText(in html: String) -> [String] {
    var found: [String] = []
    let withoutSVG = html.replacingOccurrences(of: #"<svg[\s\S]*?</svg>"#, with: "", options: .regularExpression)
    let textNodes = try! Regex(#">([^<]+)<"#)
    for match in withoutSVG.matches(of: textNodes) {
        found.append(String(match.output[1].substring!))
    }
    let attributes = try! Regex(#"(?:aria-label|title|alt|data-copied|data-failed)="([^"]*)""#)
    for match in withoutSVG.matches(of: attributes) {
        found.append(String(match.output[1].substring!))
    }
    return found.map(unescape).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
}

private func unescape(_ text: String) -> String {
    text.replacingOccurrences(of: "&#39;", with: "'").replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
        .replacingOccurrences(of: "&amp;", with: "&")
}

/// Whether a piece of page text is one of the table's values, with any
/// placeholder standing for any text.
private func isFromTheTable(_ piece: String) -> Bool {
    Strings.english.table.values.contains { value in
        let pattern =
            "^"
            + NSRegularExpression.escapedPattern(for: value)
            .replacingOccurrences(of: #"\\\{[a-z]+\\\}"#, with: ".+", options: .regularExpression) + "$"
        return piece.range(of: pattern, options: .regularExpression) != nil
    }
}

/// No page writes interface words of its own: every word a reader sees comes
/// from the string table. (The development gallery is excluded; its content
/// is invented for layout.)
@Test(arguments: [
    "/", "/today", "/plans", "/plans/psalm-a-day", "/plans/psalm-a-day/week", "/progress", "/settings",
    "/no-such-page",
])
func pagesShowOnlyTableText(path: String) async throws {
    var configuration = ServerConfiguration()
    configuration.logLevel = .warning
    try await buildApplication(configuration).test(.router) { client in
        try await client.execute(uri: path, method: .get) { response in
            let pieces = readerText(in: String(buffer: response.body))
            #expect(!pieces.isEmpty)
            for piece in pieces {
                #expect(isFromTheTable(piece), "not from the string table: \(piece)")
            }
        }
    }
}

/// The components' fixed words come from the table too.
@Test func componentsShowOnlyTableText() {
    let mark = Reference(display: "Mark 4:1–20", spoken: "Mark, chapter 4, verses 1 to 20")
    let html = [
        Components.copyButton(mark), Components.workload(minutes: 3), Components.undoBanner(""),
        Components.state(.loading), Components.state(.offline), Components.state(.error(message: "")),
        Components.sampleWeek([]), Components.sourceNote(""),
        Components.changePreview(title: "", explanation: "", changes: [], confirm: ""),
    ].map(\.rendered).joined()
    for piece in readerText(in: html) where piece != "→" {
        #expect(isFromTheTable(piece), "not from the string table: \(piece)")
    }
}
