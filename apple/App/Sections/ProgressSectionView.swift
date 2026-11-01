import SwiftUI

/// Progress, as a placeholder until progress and history are built (Phase 11).
/// (SwiftUI already has a `ProgressView`.)
struct ProgressSectionView: View {
    var body: some View {
        ScrollView {
            StateMessage(
                kind: .empty(
                    title: String(localized: "Your reading record will appear here."),
                    message: String(localized: "It describes what you've read, and nothing more.")))
        }
        .background(Palette.background)
        .navigationTitle("Progress")
    }
}

#Preview {
    NavigationStack { ProgressSectionView() }
}
