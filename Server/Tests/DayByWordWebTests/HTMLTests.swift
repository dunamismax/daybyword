import Testing

@testable import DayByWordWeb

@Test func escapesInterpolatedText() {
    let title = #"Psalms & "Proverbs" <script>'x'</script>"#
    let html: HTML = "<h1>\(title)</h1>"
    #expect(html.rendered == "<h1>Psalms &amp; &quot;Proverbs&quot; &lt;script&gt;&#39;x&#39;&lt;/script&gt;</h1>")
}

@Test func includesHTMLAndNumbersAsTheyAre() {
    let item: HTML = "<li>Reading \(12)</li>"
    let list: HTML = "<ul>\(HTML([item, item]))</ul>"
    #expect(list.rendered == "<ul><li>Reading 12</li><li>Reading 12</li></ul>")
}

@Test func leavesOrdinaryTextAlone() {
    #expect(HTML.escape("Song of Songs 2:1–7 · Ecclesiasticus") == "Song of Songs 2:1–7 · Ecclesiasticus")
}
