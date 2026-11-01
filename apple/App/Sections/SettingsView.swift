import SwiftUI

/// Settings, opened from the toolbar of each section. A placeholder until the
/// Settings shell is built (P2.11).
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                StateMessage(
                    kind: .empty(
                        title: String(localized: "Settings will appear here."),
                        message: String(
                            localized: "Day by Word is independent and not affiliated with any church or denomination.")
                    )
                )
            }
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
}

#Preview {
    SettingsView()
}
