import SwiftUI

/// Plans, as a placeholder until choosing a plan is built (Phase 9).
struct PlansView: View {
    var body: some View {
        ScrollView {
            StateMessage(
                kind: .empty(
                    title: String(localized: "Plans will appear here."),
                    message: String(localized: "You'll be able to choose a reading plan here.")))
        }
        .background(Palette.background)
        .navigationTitle("Plans")
    }
}

/// A plan's page, as a placeholder until plan pages are built (P9.4).
struct PlanView: View {
    let id: String

    var body: some View {
        ScrollView {
            StateMessage(
                kind: .empty(
                    title: String(localized: "This plan's page will appear here."),
                    message: String(localized: "Plan pages arrive with the catalog.")))
        }
        .background(Palette.background)
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { PlansView() }
}
