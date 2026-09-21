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
    private static let titleParagraphStyle: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 24
        return style
    }()
    private static let linkDetector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
    )
    private static let headingExpression = try! NSRegularExpression(
        pattern: #"(?m)^(#{1,6})[ \t]+(.+)$"#
    )
    private static let strongExpression = try! NSRegularExpression(
        pattern: #"(\*\*|__)(?=\S)(.+?)(?<=\S)\1"#
    )
    private static let emphasisExpression = try! NSRegularExpression(
        pattern: #"(?<!\*)\*(?=\S)(.+?)(?<=\S)\*(?!\*)|(?<!_)_(?=\S)(.+?)(?<=\S)_(?!_)"#
    )
    private static let strikeExpression = try! NSRegularExpression(
        pattern: #"~~(?=\S)(.+?)(?<=\S)~~"#
    )
    private static let codeExpression = try! NSRegularExpression(
        pattern: #"`([^`\n]+)`"#
    )
    private static let markdownLinkExpression = try! NSRegularExpression(
        pattern: #"\[([^\]\n]+)\]\((https?://[^)\s]+|mailto:[^)\s]+)\)"#
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
        [
            .font: AppFont.uiFont(.title, compatibleWith: traits),
            .foregroundColor: titleColor,
            .paragraphStyle: titleParagraphStyle,
        ]
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

        let headings = matches(headingExpression, in: text)
        let hasExplicitTitle = headings.contains { $0.range(at: 1).length == 1 }
        if !hasExplicitTitle {
            let title = titleRange(in: text)
            if title.length > 0 {
                storage.addAttributes(titleAttributes(traits: traits), range: title)
            }
        }

        for match in headings {
            let level = match.range(at: 1).length
            let content = match.range(at: 2)
            let scale: AppFont.Scale = level == 1 ? .title : (level <= 3 ? .headline : .subhead)
            storage.addAttributes([
                .font: AppFont.uiFont(scale, compatibleWith: traits),
                .foregroundColor: titleColor,
            ], range: content)
            let prefix = NSRange(
                location: match.range.location,
                length: content.location - match.range.location
            )
            conceal(prefix, in: storage, traits: traits)
        }

        applyInlineMarkdown(to: storage, text: text, traits: traits)

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

    private static func applyInlineMarkdown(
        to storage: NSTextStorage,
        text: String,
        traits: UITraitCollection?
    ) {
        for match in matches(strongExpression, in: text) {
            let content = match.range(at: 2)
            storage.addAttribute(.font, value: font(in: storage, at: content.location, adding: .traitBold), range: content)
            concealDelimiters(of: match.range, around: content, in: storage, traits: traits)
        }

        for match in matches(emphasisExpression, in: text) {
            let content = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 2)
            guard content.location != NSNotFound else { continue }
            storage.addAttribute(.font, value: font(in: storage, at: content.location, adding: .traitItalic), range: content)
            concealDelimiters(of: match.range, around: content, in: storage, traits: traits)
        }

        for match in matches(strikeExpression, in: text) {
            let content = match.range(at: 1)
            storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: content)
            concealDelimiters(of: match.range, around: content, in: storage, traits: traits)
        }

        for match in matches(codeExpression, in: text) {
            let content = match.range(at: 1)
            let base = (storage.attribute(.font, at: content.location, effectiveRange: nil) as? UIFont)
                ?? AppFont.uiFont(.body, compatibleWith: traits)
            storage.addAttributes([
                .font: UIFont.monospacedSystemFont(ofSize: base.pointSize, weight: .regular),
                .backgroundColor: UIColor(Material.Surface.secondary),
            ], range: content)
            concealDelimiters(of: match.range, around: content, in: storage, traits: traits)
        }

        for match in matches(markdownLinkExpression, in: text) {
            let label = match.range(at: 1)
            storage.addAttributes([
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor(Material.Text.accent),
            ], range: label)
            concealDelimiters(of: match.range, around: label, in: storage, traits: traits)
        }
    }

    private static func matches(_ expression: NSRegularExpression, in text: String) -> [NSTextCheckingResult] {
        expression.matches(
            in: text,
            range: NSRange(location: 0, length: (text as NSString).length)
        )
    }

    private static func concealDelimiters(
        of whole: NSRange,
        around content: NSRange,
        in storage: NSTextStorage,
        traits: UITraitCollection?
    ) {
        conceal(NSRange(location: whole.location, length: content.location - whole.location), in: storage, traits: traits)
        conceal(
            NSRange(location: content.upperBound, length: whole.upperBound - content.upperBound),
            in: storage,
            traits: traits
        )
    }

    /// Delimiters stay in the backing string so saving, undo and cursor offsets
    /// remain lossless, but collapse visually to produce the WYSIWYG surface.
    private static func conceal(
        _ range: NSRange,
        in storage: NSTextStorage,
        traits: UITraitCollection?
    ) {
        guard range.length > 0 else { return }
        storage.addAttributes([
            .font: UIFont.systemFont(ofSize: 0.1),
            .foregroundColor: UIColor.clear,
        ], range: range)
    }

    private static func font(
        in storage: NSTextStorage,
        at location: Int,
        adding trait: UIFontDescriptor.SymbolicTraits
    ) -> UIFont {
        let existing = (storage.attribute(.font, at: location, effectiveRange: nil) as? UIFont)
            ?? AppFont.uiFont(.body)
        guard let descriptor = existing.fontDescriptor.withSymbolicTraits(
            existing.fontDescriptor.symbolicTraits.union(trait)
        ) else { return existing }
        return UIFont(descriptor: descriptor, size: existing.pointSize)
    }
}
