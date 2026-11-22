import UIKit

/// The system's share sheet for a file, presented over whatever is showing.
///
/// Settings is itself a sheet, and SwiftUI's `ShareLink` inside it closed
/// Settings instead of sharing (iOS 27 Simulator, 2026-11-21; P8.13). UIKit
/// presents the share sheet from the topmost view controller, so Settings
/// stays open beneath it.
@MainActor
enum ShareSheet {
    static func present(_ file: URL) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard var top = scene?.keyWindow?.rootViewController else { return }
        while let presented = top.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        let controller = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        // On iPad the share sheet is a popover, here from the middle of the
        // screen with no arrow.
        if let popover = controller.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        top.present(controller, animated: true)
    }
}
