import SwiftUI

/// Whether Progress shows the reading days read in a row (D17, P11.3): off
/// unless the reader turns it on, counted against their own reading days,
/// shown small, and never in a reminder.
enum StreakDisplay: String, CaseIterable, Sendable {
    case off
    case on

    static let storageKey = "streak"
}

/// How the app looks, whatever the device is set to (docs/product.md,
/// Settings). Kept in user defaults: a display preference, not reading data.
enum Appearance: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case light
    case dark

    static let storageKey = "appearance"

    var id: Self { self }

    var label: LocalizedStringResource {
        switch self {
        case .automatic: "Automatic"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// The color scheme to ask for; nil follows the device.
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// How large references are set, on top of the reader's Dynamic Type size.
enum ReferenceSize: String, CaseIterable, Identifiable, Sendable {
    case standard
    case larger
    case largest

    static let storageKey = "referenceSize"

    var id: Self { self }

    var label: LocalizedStringResource {
        switch self {
        case .standard: "Standard"
        case .larger: "Larger"
        case .largest: "Largest"
        }
    }

    var scale: CGFloat {
        switch self {
        case .standard: 1
        case .larger: 1.25
        case .largest: 1.5
        }
    }
}

extension EnvironmentValues {
    /// The reader's reference size, applied by `ReferenceBlock`.
    @Entry var referenceScale: CGFloat = 1
}

/// Settings, opened from the toolbar of each section (BUILD.md P2.11).
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.automatic
    @AppStorage(ReferenceSize.storageKey) private var referenceSize = ReferenceSize.standard
    @AppStorage(WayToRead.storageKey) private var wayToRead = WayToRead.physicalBible
    @AppStorage(WayToRead.keepAwakeKey) private var keepAwake = false
    @AppStorage(StreakDisplay.storageKey) private var streak = StreakDisplay.off
    @Environment(Library.self) private var library
    @State private var confirmingDelete = false
    @State private var failure: String?
    /// The reading record, written out when Settings opens, for the share sheet.
    @State private var exportFile: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("How you read", selection: $wayToRead) {
                        ForEach(WayToRead.allCases) { Text($0.label).tag($0) }
                    }
                    .formPicker()
                    if wayToRead == .physicalBible {
                        Toggle("Keep the screen awake on Today", isOn: $keepAwake)
                    }
                    if wayToRead == .youVersion {
                        TranslationPicker()
                    }
                } footer: {
                    Group {
                        switch wayToRead {
                        case .physicalBible: Text("With a physical Bible, Today says where each reading is in print.")
                        case .youVersion: TranslationFooter()
                        case .otherApp: Text("Day by Word never shows Bible text. Copy reference works with any app.")
                        }
                    }
                    .sectionNote()
                }
                .listRowBackground(Palette.surface)

                RemindersSection()

                Section {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                    }
                    .formPicker()
                } footer: {
                    Text("Automatic follows your device.").sectionNote()
                }
                .listRowBackground(Palette.surface)

                Section {
                    Picker("Reference text size", selection: $referenceSize) {
                        ForEach(ReferenceSize.allCases) { Text($0.label).tag($0) }
                    }
                    .formPicker()
                    ReferenceBlock(reference: Self.sample)
                        .environment(\.referenceScale, referenceSize.scale)
                        .accessibilityHint(Text("A sample reference at this size."))
                } footer: {
                    Text("References on Today and in plans use this size, on top of your device's text size.")
                        .sectionNote()
                }
                .listRowBackground(Palette.surface)

                Section {
                    Toggle(
                        "Show reading days in a row on Progress",
                        isOn: Binding(get: { streak == .on }, set: { streak = $0 ? .on : .off }))
                } footer: {
                    Group {
                        Text(
                            "Counts the reading days you've read one after another. Rest days never break it, and it never appears in a reminder."
                        )
                    }
                    .sectionNote()
                }
                .listRowBackground(Palette.surface)

                if let catalog = library.catalog {
                    Section {
                        Picker("Book names", selection: Bindable(library).convention) {
                            ForEach(catalog.registry.conventions, id: \.id) { convention in
                                Text(verbatim: convention.label).tag(convention.id)
                            }
                        }
                        .formPicker()
                    } footer: {
                        Group {
                            if let example = catalog.registry.conventions.first(where: { $0.id == library.convention })?
                                .example
                            {
                                Text(verbatim: example)
                            }
                        }
                        .sectionNote()
                    }
                    .listRowBackground(Palette.surface)
                }

                Section {
                    if let exportFile {
                        Button("Export my reading record") { ShareSheet.present(exportFile) }
                    }
                    Button("Delete everything on this device", role: .destructive) { confirmingDelete = true }
                    if let failure {
                        Text(verbatim: failure).foregroundStyle(Palette.danger)
                    }
                } header: {
                    Text("Your data").sectionNote()
                } footer: {
                    Group {
                        Text(
                            "Your plans and reading record are kept only on this device. The export is a JSON file of everything you've done."
                        )
                    }
                    .sectionNote()
                }
                .listRowBackground(Palette.surface)
                .confirmationDialog(
                    "Delete everything?", isPresented: $confirmingDelete, titleVisibility: .visible
                ) {
                    Button("Delete everything", role: .destructive) {
                        do { try library.deleteEverything() } catch {
                            failure = String(localized: "Nothing was deleted: \(String(describing: error))")
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This removes your plans and reading record from this device. It can't be undone.")
                }

                Section {
                    Text("Day by Word is independent and not affiliated with any church or denomination.")
                    // The web's support page: the address, reporting a
                    // reading that looks wrong, and what is kept (P16.2).
                    Link("Help and support", destination: Self.web("/support"))
                    // Where each plan comes from, and the standard it meets (P16.5).
                    Link("Sources and permissions", destination: Self.web("/sources"))
                    Link("How plans are chosen", destination: Self.web("/criteria"))
                    Link("Accessibility", destination: Self.web("/accessibility"))
                    // The privacy policy and terms the owner approved (P16.3).
                    Link("Privacy policy", destination: Self.web("/privacy"))
                    Link("Terms of use", destination: Self.web("/terms"))
                    LabeledContent("Version", value: Self.version)
                } header: {
                    Text("About").sectionNote()
                }
                .listRowBackground(Palette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .task(id: library.journal?.events.count) { exportFile = try? library.export().file() }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            // A sheet sits outside the tab view's tint.
            .tint(Palette.accent)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private static let sample = ReferenceText(
        display: String(localized: "Mark 4:1–20"), spoken: String(localized: "Mark, chapter 4, verses 1 to 20"))

    /// A public page on daybyword.com: support (P16.2), sources and the criteria (P16.5), accessibility (P16.6), privacy and terms (P16.3).
    static func web(_ path: String) -> URL { URL(string: "https://\(AppRoute.webHost)\(path)")! }

    /// The running build: "0.1.0 (25)".
    nonisolated static var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let marketing = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        return "\(marketing) (\(build))"
    }
}

#Preview {
    let library = Library.live()
    SettingsView().environment(library).environment(ReminderScheduler(library: library))
}
