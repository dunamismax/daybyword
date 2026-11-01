import SwiftUI

/// Today, as a placeholder until the first plans arrive (P8.3). It uses the
/// Morning tokens (docs/design.md).
struct TodayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Your next reading will appear here.")
                    .typeStyle(TypeScale.referenceList)
                Text("Find your plan. Read your Bible. Keep your place.")
                    .typeStyle(TypeScale.body)
                    .foregroundStyle(Palette.textMuted)
                Text("Day by Word is in development.")
                    .typeStyle(TypeScale.caption)
                    .foregroundStyle(Palette.textMuted)
                    .padding(.top, Spacing.l)
            }
            .foregroundStyle(Palette.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.m)
        }
        .background(Palette.background)
        .navigationTitle("Today")
    }
}

#Preview {
    NavigationStack { TodayView() }
}
