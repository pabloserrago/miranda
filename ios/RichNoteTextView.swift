import SwiftUI
import UIKit

/// Handle the editor's chrome uses to drive the text view: undo, and focus.
/// The view itself is owned by UIKit, so the buttons above it need a way in.
@MainActor
final class NoteEditorController: ObservableObject {
    /// Drives the undo button's enabled state.
    @Published var canUndo = false

    fileprivate weak var textView: UITextView?

    func undo() {
        textView?.undoManager?.undo()
        refreshUndoState()
    }

    func focus() {
        textView?.becomeFirstResponder()
    }

    func blur() {
        textView?.resignFirstResponder()
    }

    fileprivate func refreshUndoState() {
        let available = textView?.undoManager?.canUndo ?? false
        if canUndo != available { canUndo = available }
    }
}

/// The note editor's text surface. A plain `TextEditor` renders one uniform
/// style, so notes are edited in a `UITextView` whose attributes are recomputed
/// by `NoteTextStyler` on every change: first line as the title, the rest as
/// body, URLs underlined.
///
/// Deliberately not placed inside a `.background` modifier — iOS 26 stopped
/// rendering `UIViewRepresentable` views there (see docs/test-learnings.md).
struct RichNoteTextView: UIViewRepresentable {
    @Binding var text: String
    let controller: NoteEditorController
    /// Re-runs `updateUIView` on a Larger Text change so the fonts rescale
    /// without a relaunch, matching how `AppFont` re-resolves.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func makeCoordinator() -> Coordinator { Coordinator(text: $text, controller: controller) }

    func makeUIView(context: Context) -> UITextView {
        // TextKit 1 explicitly: reading `textStorage` on a TextKit 2 view forces
        // a silent downgrade, so ask for it up front and keep the behaviour
        // predictable.
        let textView = UITextView(usingTextLayoutManager: false)
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.tintColor = UIColor(Material.Text.primary)
        textView.typingAttributes = NoteTextStyler.typingAttributes(
            for: text,
            at: 0,
            traits: textView.traitCollection
        )
        textView.accessibilityIdentifier = "note-text-editor"
        textView.accessibilityLabel = String(
            localized: "Note",
            comment: "Accessibility label for the note text editor"
        )

        textView.text = text
        context.coordinator.restyle(textView)
        controller.textView = textView
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.text = $text

        // Only reachable from outside the text view — dictation appending a
        // transcript, or a segment being merged back in. Typing arrives through
        // the delegate instead, so this must not fight it.
        if textView.text != text {
            let wasAtEnd = textView.selectedRange.location >= (textView.text as NSString).length
            textView.text = text
            if wasAtEnd {
                let end = (text as NSString).length
                textView.selectedRange = NSRange(location: end, length: 0)
            }
            context.coordinator.restyle(textView)
        } else if context.coordinator.styledContentSize != dynamicTypeSize {
            context.coordinator.restyle(textView)
        }
        context.coordinator.styledContentSize = dynamicTypeSize
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        let controller: NoteEditorController
        var styledContentSize: DynamicTypeSize?

        init(text: Binding<String>, controller: NoteEditorController) {
            self.text = text
            self.controller = controller
        }

        /// Reapplies the styling rules. Attributes are replaced in place rather
        /// than the string being reassigned, which is what lets the text view's
        /// own undo stack survive a restyle.
        func restyle(_ textView: UITextView) {
            // Mid-composition (Japanese, Chinese, any marked-text IME) the
            // provisional text must be left alone or composition breaks.
            guard textView.markedTextRange == nil else { return }

            let selection = textView.selectedRange
            NoteTextStyler.apply(to: textView.textStorage, traits: textView.traitCollection)
            textView.selectedRange = selection
            textView.typingAttributes = NoteTextStyler.typingAttributes(
                for: textView.text,
                at: selection.location,
                traits: textView.traitCollection
            )
        }

        func textViewDidChange(_ textView: UITextView) {
            guard textView.markedTextRange == nil else { return }
            text.wrappedValue = textView.text
            restyle(textView)
            controller.refreshUndoState()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard textView.markedTextRange == nil else { return }
            textView.typingAttributes = NoteTextStyler.typingAttributes(
                for: textView.text,
                at: textView.selectedRange.location,
                traits: textView.traitCollection
            )
        }
    }
}
