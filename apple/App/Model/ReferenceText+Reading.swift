import Foundation
import ReadingEngine

extension ReferenceText {
    /// A reading as it is shown ("Mark 4:1–20", from the engine's formatter)
    /// and as VoiceOver says it ("Mark, chapter 4, verses 1 to 20"), the
    /// same words the web uses (web/src/lib/reference.ts).
    init(_ reading: Reading, formatter: ReferenceFormatter) {
        self.init(display: formatter.string(for: reading), spoken: SpokenReference.text(reading, formatter: formatter))
    }
}
