import SwiftUI

/// Today, as a placeholder until the design is chosen (BUILD.md P2.3) and the
/// shell is built (P2.7). It uses only the system's semantic colors and text
/// styles, so it follows light and dark mode and Dynamic Type.
struct TodayView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your next reading will appear here.")
                        .font(.title2)
                    Text("Find your plan. Read your Bible. Keep your place.")
                        .foregroundStyle(.secondary)
                    Text("Day by Word is in development.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}
