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

    var body: some View {
        NavigationStack {
            Form {
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

                Section("About") {
                    Text("Day by Word is independent and not affiliated with any church or denomination.")
                    LabeledContent("Version", value: Self.version)
                }
                .listRowBackground(Palette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
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
    SettingsView()
}
