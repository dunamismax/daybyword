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
    }
}
