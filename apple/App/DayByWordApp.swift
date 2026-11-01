import SwiftUI

@main
struct DayByWordApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-componentGallery") {
                    ComponentGallery()
                } else {
                    RootView()
                }
            #else
                RootView()
            #endif
        }
    }
}
