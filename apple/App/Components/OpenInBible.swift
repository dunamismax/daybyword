import ReadingEngine
import SwiftUI

extension WayToRead {
    /// The Bible.com number of the translation YouVersion links open in; 0
    /// until the reader chooses one (docs/destinations.md).
    static let translationKey = "translation"
}

/// The translation YouVersion links open in: the reader's choice, from the
/// translations Day by Word has checked on Bible.com, with no default
/// (docs/destinations.md, rule 3).
struct TranslationPicker: View {
    @AppStorage(WayToRead.translationKey) private var translation = 0

    var body: some View {
        NavigationLink {
            TranslationList(selection: $translation)
        } label: {
            LabeledContent("Translation") {
                if let chosen = BibleTranslation.withID(translation) {
                    Text(verbatim: chosen.abbreviation)
                } else {
                    Text("Not chosen")
                }
            }
        }
    }
}

/// Every translation Day by Word links to, in alphabetical order of name.
struct TranslationList: View {
    @Binding var selection: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                ForEach(BibleTranslation.all) { translation in
                    Button {
                        selection = translation.id
                        dismiss()
                    } label: {
                        HStack {
                            Text(verbatim: "\(translation.name) (\(translation.abbreviation))")
                                .foregroundStyle(Palette.text)
                            Spacer(minLength: Spacing.xs)
                            if selection == translation.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Palette.accent)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .accessibilityAddTraits(selection == translation.id ? .isSelected : [])
                }
            } footer: {
                Group {
                    TranslationFooter()
                }
                .sectionNote()
            }
            .listRowBackground(Palette.surface)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .navigationTitle("Translation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// What the translation picker's section says beneath it.
struct TranslationFooter: View {
    var body: some View {
        Text(
            "Readings open in the YouVersion app if it's installed, and on Bible.com if not. Links use the common English verse numbers, and a few translations number some chapters differently."
        )
    }
}

/// Open in YouVersion, for a reader who reads there (P8.5, D26): one
/// Bible.com address, which opens the app where it is installed. Opening a
/// reading never marks it; the reader does that.
struct OpenInYouVersion: View {
    let reading: Reading
    let formatter: ReferenceFormatter
    let spoken: String

    @AppStorage(WayToRead.translationKey) private var translationID = 0
    @Environment(\.openURL) private var openURL

    private var link: BibleLink? {
        BibleTranslation.withID(translationID).map {
            BibleLink(reading, translation: $0, in: formatter.versification)
        }
    }

    var body: some View {
        if let link, let url = URL(string: link.address) {
            Button("Open in YouVersion") { openURL(url) }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint(Text(hint(link)))
        }
    }

    private func hint(_ link: BibleLink) -> String {
        link.isWholeReading
            ? String(localized: "Opens \(spoken) in YouVersion or on Bible.com.")
            : String(localized: "Opens \(Self.chapter(link, formatter: formatter)) in YouVersion or on Bible.com.")
    }

    /// "Matthew 1", "Psalm 119": the chapter a link opens at.
    static func chapter(_ link: BibleLink, formatter: ReferenceFormatter) -> String {
        guard let passage = try? Passage(link.book, chapter: link.chapter, in: formatter.versification),
            let reading = try? Reading([passage])
        else { return "\(link.book) \(link.chapter)" }
        return formatter.string(for: reading)
    }
}

/// The line beneath a reading for a YouVersion reader: where a link opens
/// when it cannot hold the whole reading, or where to choose a translation.
struct OpenInYouVersionNote: View {
    let reading: Reading
    let formatter: ReferenceFormatter

    @AppStorage(WayToRead.translationKey) private var translationID = 0
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        if let translation = BibleTranslation.withID(translationID) {
            let link = BibleLink(reading, translation: translation, in: formatter.versification)
            if !link.isWholeReading {
                Text(
                    "Opens at \(OpenInYouVersion.chapter(link, formatter: formatter)), where this reading begins."
                )
                .typeStyle(TypeScale.caption)
                .foregroundStyle(Palette.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            Button {
                navigation.showingSettings = true
            } label: {
                Text("Choose a translation to open readings in YouVersion")
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .typeStyle(TypeScale.caption)
            .foregroundStyle(Palette.accent)
        }
    }
}
