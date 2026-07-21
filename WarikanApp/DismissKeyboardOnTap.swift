import SwiftUI
import UIKit

// ─────────────────────────────────────────────────────────────
// DismissKeyboardOnTap — installs a window-level tap recognizer so a
// tap ANYWHERE outside the keyboard closes it, the way SwiftUI's own
// gestures can't:
//   • .onTapGesture on a container swallows button taps.
//   • .simultaneousGesture fires on the TextFields too and steals focus.
// A UIKit recognizer with `cancelsTouchesInView = false` lets every
// other touch (buttons, fields) keep working; its delegate ignores taps
// that land on a UITextField so tapping a field doesn't dismiss it.
//
// Place as a zero-size .background(...) on the screen's root view.
// ─────────────────────────────────────────────────────────────
struct DismissKeyboardOnTap: UIViewRepresentable {
    var onTap: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        // The window isn't attached yet at make-time; defer until it is.
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            let tap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap))
            tap.cancelsTouchesInView = false   // let the touch reach buttons/fields
            tap.delegate = context.coordinator
            window.addGestureRecognizer(tap)
            context.coordinator.recognizer = tap
            context.coordinator.window = window
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTap = onTap
    }

    // Remove the recognizer when the screen goes away, so it doesn't pile
    // up on the shared window or linger on other screens.
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        if let tap = coordinator.recognizer {
            coordinator.window?.removeGestureRecognizer(tap)
        }
        coordinator.recognizer = nil
        coordinator.window = nil
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTap: () -> Void
        weak var recognizer: UITapGestureRecognizer?
        weak var window: UIWindow?

        init(onTap: @escaping () -> Void) { self.onTap = onTap }

        @objc func handleTap() { onTap() }

        // Recognize alongside everything else (SwiftUI buttons, scroll, etc.)
        // so tapping the camera tab or the ± quantity buttons fires the button
        // AND still closes the keyboard — otherwise the button's own recognizer
        // wins and the window tap never fires.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }

        // Don't dismiss when the tap lands on a text field — let it focus /
        // switch fields normally. Every other tap closes the keyboard.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldReceive touch: UITouch) -> Bool {
            var v = touch.view
            while let current = v {
                if current is UITextField { return false }
                v = current.superview
            }
            return true
        }
    }
}
