import UIKit
import SwiftUI

/// Attaches a UILongPressGestureRecognizer to the enclosing UITableViewCell's contentView.
///
/// Why: SwiftUI's DragGesture adds a UIPanGestureRecognizer to each list cell. UITableView's
/// built-in swipe-action recognizer is also a pan recognizer, and the two compete — swipe actions
/// lose. A UILongPressGestureRecognizer is a different gesture type that doesn't conflict with the
/// table's pan recognizer. After the hold fires, the recognizer's .changed state provides
/// continuous position updates so we can track the drag without any separate DragGesture.
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

    /// Zero-size, non-interactive view used only as an anchor to traverse up the
    /// view hierarchy and find the UITableViewCell.
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
            // Allow unlimited movement so the recognizer stays alive through the drag phase.
            r.allowableMovement = 10_000
            return r
        }()

        init(_ config: LongPressDragGesture) { self.config = config }

        /// Traverse up the view hierarchy to find the UITableViewCell's contentView and
        /// attach the gesture recognizer there. Idempotent.
        func ensureAttached(near view: UIView) {
            var current: UIView? = view.superview
            while let v = current {
                if let cell = v as? UITableViewCell {
                    let contentView = cell.contentView
                    guard attachedTarget !== contentView else { return }
                    attachedTarget?.removeGestureRecognizer(recognizer)
                    contentView.addGestureRecognizer(recognizer)
                    attachedTarget = contentView
                    return
                }
                current = v.superview
            }
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
