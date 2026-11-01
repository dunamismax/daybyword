import SwiftUI

/// The app's shell: Today, Plans, and Progress as tabs, each with its own
/// navigation stack, and Settings from a toolbar button on each tab's root
/// (docs/product.md, Navigation).
struct RootView: View {
    @State private var navigation = AppNavigation()
    @SceneStorage("navigation") private var savedNavigation = Data()
    @State private var restored = false
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.automatic
    @AppStorage(ReferenceSize.storageKey) private var referenceSize = ReferenceSize.standard

    var body: some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.selectedTab) {
            Tab("Today", systemImage: "sun.horizon", value: AppTab.today) {
                SectionStack(path: $navigation.todayPath) { TodayView() }
            }
            Tab("Plans", systemImage: "books.vertical", value: AppTab.plans) {
                SectionStack(path: $navigation.plansPath) { PlansView() }
            }
            Tab("Progress", systemImage: "calendar", value: AppTab.progress) {
                SectionStack(path: $navigation.progressPath) { ProgressSectionView() }
            }
        }
        .tint(Palette.accent)
        .sheet(isPresented: $navigation.showingSettings) {
            SettingsView()
                .preferredColorScheme(appearance.colorScheme)
        }
        .environment(\.referenceScale, referenceSize.scale)
        .preferredColorScheme(appearance.colorScheme)
        .environment(navigation)
        .onAppear {
            guard !restored else { return }
            restored = true
            navigation.restore(from: savedNavigation)
        }
        .onChange(of: navigation.saved) {
            savedNavigation = navigation.encoded
        }
        .onOpenURL { url in
            navigation.open(url)
        }
    }
}

/// One section's navigation stack, with the Settings button on its root.
private struct SectionStack<Root: View>: View {
    @Binding var path: [Destination]
    @ViewBuilder let root: Root
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        NavigationStack(path: $path) {
            root
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings", systemImage: "gearshape") {
                            navigation.showingSettings = true
                        }
                    }
                }
                .navigationDestination(for: Destination.self) { destination in
                    switch destination {
                    case .plan(let id): PlanView(id: id)
                    case .planWeek(let id, let start): PlanWeekView(id: id, start: start)
                    }
                }
        }
    }
}
