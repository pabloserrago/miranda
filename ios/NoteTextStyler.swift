import Foundation
import UIKit

/// Styling rules for the note editor. A note reads as a title followed by
/// supporting detail, so the first line takes the title face and everything
/// after it the body face. URLs are underlined wherever they appear, keeping
/// the size and color of the line they sit on.
///
/// The rules are expressed as ranges over the raw text so they can be asserted
/// without a `UITextView` (see `NoteTextStylerTests`). `apply(to:traits:)` is
/// the only entry point that touches text storage.
enum NoteTextStyler {

    // Cached so repeated styling passes compare equal by identity and so the
    // detector — which is expensive to build — is created once.
    private static let titleColor = UIColor(Material.Text.primary)
    private static let bodyColor = UIColor(Material.Text.secondary)
    private static let linkDetector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
    )

    /// The first line, excluding its newline. Empty when the note starts on a
    /// blank line, because nothing has been titled yet.
    static func titleRange(in text: String) -> NSRange {
        let ns = text as NSString
        guard ns.length > 0 else { return NSRange(location: 0, length: 0) }
        let newline = ns.rangeOfCharacter(from: .newlines)
        let length = newline.location == NSNotFound ? ns.length : newline.location
        return NSRange(location: 0, length: length)
    }

    /// Ranges of every URL in the text, including bare hosts like
    /// `loremipsum.com` and `www.` forms that carry no scheme.
    static func linkRanges(in text: String) -> [NSRange] {
        linkMatches(in: text).map(\.range)
    }

    /// Every URL in the text with the absolute URL it resolves to. The detector
    /// supplies the scheme a bare host omits, which is what makes an unschemed
    /// `loremipsum.com` openable from the preview.
    static func linkMatches(in text: String) -> [(range: NSRange, url: URL)] {
        guard let linkDetector, !text.isEmpty else { return [] }
        let full = NSRange(location: 0, length: (text as NSString).length)
        return linkDetector.matches(in: text, options: [], range: full).compactMap { match in
            guard let url = match.url else { return nil }
            return (match.range, url)
        }
    }

    /// Attributes for freshly typed text at `location`, so a keystroke lands in
    /// the right face before the next full styling pass runs.
    static func typingAttributes(
        for text: String,
        at location: Int,
        traits: UITraitCollection? = nil
    ) -> [NSAttributedString.Key: Any] {
        let title = titleRange(in: text)
        let isTitle = title.length == 0 ? location == 0 : location <= title.upperBound
        return isTitle ? titleAttributes(traits: traits) : bodyAttributes(traits: traits)
    }

    static func titleAttributes(traits: UITraitCollection? = nil) -> [NSAttributedString.Key: Any] {
        [.font: AppFont.uiFont(.title, compatibleWith: traits), .foregroundColor: titleColor]
    }

    static func bodyAttributes(traits: UITraitCollection? = nil) -> [NSAttributedString.Key: Any] {
        [.font: AppFont.uiFont(.body, compatibleWith: traits), .foregroundColor: bodyColor]
    }

    /// Restyles the whole note in place. Attributes are replaced rather than the
    /// string itself so the text view's undo stack survives a styling pass.
    static func apply(to storage: NSTextStorage, traits: UITraitCollection? = nil) {
        let text = storage.string
        let full = NSRange(location: 0, length: (text as NSString).length)
        guard full.length > 0 else { return }

        storage.beginEditing()
        storage.setAttributes(bodyAttributes(traits: traits), range: full)

        let title = titleRange(in: text)
        if title.length > 0 {
            storage.addAttributes(titleAttributes(traits: traits), range: title)
        }

        // Underline only: a tap inside an editor should place the caret, so the
        // link is styled without an `.link` attribute that would open Safari.
        for link in linkRanges(in: text) {
            storage.addAttribute(
                .underlineStyle,
                value: NSUnderlineStyle.single.rawValue,
                range: link
            )
        }
        storage.endEditing()
    }
}
