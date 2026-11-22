import SwiftUI

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
                    if wayToRead == .physicalBible {
                        Toggle("Keep the screen awake on Today", isOn: $keepAwake)
                    }
                    if wayToRead == .youVersion {
                        TranslationPicker()
                    }
                } footer: {
                    switch wayToRead {
                    case .physicalBible: Text("With a physical Bible, Today says where each reading is in print.")
                    case .youVersion: TranslationFooter()
                    case .otherApp: Text("Day by Word never shows Bible text. Copy reference works with any app.")
                    }
                }
                .listRowBackground(Palette.surface)

                Section {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                    }
                } footer: {
                    Text("Automatic follows your device.")
                }
                .listRowBackground(Palette.surface)

                Section {
                    Picker("Reference text size", selection: $referenceSize) {
                        ForEach(ReferenceSize.allCases) { Text($0.label).tag($0) }
                    }
                    ReferenceBlock(reference: Self.sample)
                        .environment(\.referenceScale, referenceSize.scale)
                        .accessibilityHint(Text("A sample reference at this size."))
                } footer: {
                    Text("References on Today and in plans use this size, on top of your device's text size.")
                }
                .listRowBackground(Palette.surface)

                if let catalog = library.catalog {
                    Section {
                        Picker("Book names", selection: Bindable(library).convention) {
                            ForEach(catalog.registry.conventions, id: \.id) { convention in
                                Text(verbatim: convention.label).tag(convention.id)
                            }
                        }
                    } footer: {
                        if let example = catalog.registry.conventions.first(where: { $0.id == library.convention })?
                            .example
                        {
                            Text(verbatim: example)
                        }
                    }
                    .listRowBackground(Palette.surface)
                }

                Section {
                    if let exportFile {
                        ShareLink(item: exportFile) { Text("Export my reading record") }
                    }
                    Button("Delete everything on this device", role: .destructive) { confirmingDelete = true }
                    if let failure {
                        Text(verbatim: failure).foregroundStyle(Palette.danger)
                    }
                } header: {
                    Text("Your data")
                } footer: {
                    Text(
                        "Your plans and reading record are kept only on this device. The export is a JSON file of everything you've done."
                    )
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

                Section("About") {
                    Text("Day by Word is independent and not affiliated with any church or denomination.")
                    LabeledContent("Version", value: Self.version)
                }
                .listRowBackground(Palette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .task(id: library.journal?.events.count) { exportFile = try? library.export().file() }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private static let sample = ReferenceText(
        display: String(localized: "Mark 4:1–20"), spoken: String(localized: "Mark, chapter 4, verses 1 to 20"))

    /// The running build: "0.1.0 (25)".
    nonisolated static var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let marketing = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        return "\(marketing) (\(build))"
    }
}

#Preview {
    SettingsView().environment(Library.live())
}
