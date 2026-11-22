import SwiftUI

@main
struct DayByWordApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-componentGallery") {
                    ComponentGallery()
                } else {
                    root
                }
            #else
                root
            #endif
        }
    }

    private var root: some View {
        RootView()
            .environment(delegate.library)
            .environment(delegate.reminders)
            .environment(delegate.routes)
            #if DEBUG
                .onAppear(perform: Self.overrideAccessibilityTraits)
            #endif
    }

    #if DEBUG
        /// `-boldText YES` and `-increaseContrast YES` turn on Bold Text and
        /// Increase Contrast for this launch, as the reader's settings would,
        /// for the accessibility audit (BUILD.md P17.2); the Simulator offers
        /// no way to set Bold Text from a test.
        private static func overrideAccessibilityTraits() {
            let defaults = UserDefaults.standard
            for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
                if defaults.bool(forKey: "boldText") { scene.traitOverrides.legibilityWeight = .bold }
                if defaults.bool(forKey: "increaseContrast") { scene.traitOverrides.accessibilityContrast = .high }
            }
        }
    #endif
}
