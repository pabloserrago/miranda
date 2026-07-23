import UIKit
import SwiftUI

/// UIViewRepresentable-based long-press-drag gesture.
///
/// NOTE: This implementation is kept for reference. ContentView uses the SwiftUI-native
/// .onLongPressGesture + .simultaneousGesture(DragGesture()) approach instead, because
/// iOS 26 no longer renders UIViewRepresentable views placed in a SwiftUI .background modifier.
///
/// If a future iOS version reintroduces the need for UIKit-level gesture control (e.g. to
/// avoid conflicts with swipe actions), this can be re-wired.
struct LongPressDragGesture: UIViewRepresentable {
    let cardId: UUID
    let cardIndex: Int
    @Binding var liftedId: UUID?
    @Binding var translation: CGSize
    let onStart: () -> Void
    let onEnd: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PassthroughView {
        PassthroughView()
    }

    func updateUIView(_ uiView: PassthroughView, context: Context) {
        context.coordinator.config = self
        DispatchQueue.main.async {
            context.coordinator.ensureAttached(near: uiView)
        }
    }

    // MARK: - PassthroughView

    /// Zero-size, non-interactive anchor for hierarchy traversal.
    final class PassthroughView: UIView {
        init() {
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }
        required init?(coder: NSCoder) { fatalError() }
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {
        var config: LongPressDragGesture
        var startY: CGFloat = 0
        weak var attachedTarget: UIView?

        lazy var recognizer: UILongPressGestureRecognizer = {
            let r = UILongPressGestureRecognizer(target: self, action: #selector(handle(_:)))
            r.minimumPressDuration = 0.45
            r.allowableMovement = 10_000
            return r
        }()

        init(_ config: LongPressDragGesture) { self.config = config }

        /// Traverse up the view hierarchy to find a list cell's contentView.
        /// Checks UICollectionViewCell (iOS 16+) and UITableViewCell (iOS 15 and earlier).
        /// Falls back to the nearest interactive non-scroll ancestor if no cell is found.
        func ensureAttached(near view: UIView) {
            var current: UIView? = view.superview
            while let v = current {
                if let cell = v as? UICollectionViewCell {
                    attach(to: cell.contentView); return
                }
                if let cell = v as? UITableViewCell {
                    attach(to: cell.contentView); return
                }
                current = v.superview
            }
            var fallback: UIView? = view.superview
            while let v = fallback {
                if v is UIScrollView || v is UIWindow { break }
                if v.isUserInteractionEnabled { attach(to: v); return }
                fallback = v.superview
            }
        }

        private func attach(to target: UIView) {
            guard attachedTarget !== target else { return }
            attachedTarget?.removeGestureRecognizer(recognizer)
            target.addGestureRecognizer(recognizer)
            attachedTarget = target
        }

        @objc func handle(_ r: UILongPressGestureRecognizer) {
            let y = r.location(in: nil).y
            switch r.state {
            case .began:
                startY = y
                config.onStart()
            case .changed:
                guard config.liftedId == config.cardId else { return }
                config.translation = CGSize(width: 0, height: y - startY)
            case .ended, .cancelled, .failed:
                config.onEnd(y - startY)
            default:
                break
            }
        }
    }
}
