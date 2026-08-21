import Foundation
import UIKit
import Testing
@testable import ios

/// Covers the note editor's styling rules: the first line reads as the note's
/// title, everything after it as body, and any URL is underlined wherever it
/// appears. The rules are pure functions over the text so they can be asserted
/// without standing up a UITextView.
struct NoteTextStylerTests {

    // MARK: Title range

    @Test func titleRangeCoversFirstLineOnly() {
        let text = "Buy the plane tickets\nLorem ipsum dolor sit amet"
        #expect(NoteTextStyler.titleRange(in: text) == NSRange(location: 0, length: 21))
    }

    @Test func titleRangeSingleLine() {
        let text = "Buy the plane tickets"
        #expect(NoteTextStyler.titleRange(in: text) == NSRange(location: 0, length: 21))
    }

    @Test func titleRangeEmptyText() {
        #expect(NoteTextStyler.titleRange(in: "") == NSRange(location: 0, length: 0))
    }

    @Test func titleRangeLeadingNewline() {
        // Nothing typed on the first line means there is no title yet.
        #expect(NoteTextStyler.titleRange(in: "\nBody only") == NSRange(location: 0, length: 0))
    }

    @Test func titleRangeCountsUTF16ForEmoji() {
        // NSRange is UTF-16 based; a non-BMP emoji occupies two units.
        let text = "🛒 milk\nbody"
        #expect(NoteTextStyler.titleRange(in: text) == NSRange(location: 0, length: 7))
    }

    // MARK: Link detection

    @Test func linkRangesDetectsAllThreeURLForms() {
        // The three forms the design shows underlined.
        let scheme = NoteTextStyler.linkRanges(in: "https://loremipsum.com")
        #expect(scheme.count == 1)
        #expect(scheme.first == NSRange(location: 0, length: 22))

        let bare = NoteTextStyler.linkRanges(in: "loremipsum.com")
        #expect(bare.count == 1)
        #expect(bare.first == NSRange(location: 0, length: 14))

        let www = NoteTextStyler.linkRanges(in: "www.loremipsum.com")
        #expect(www.count == 1)
        #expect(www.first == NSRange(location: 0, length: 18))
    }

    @Test func linkRangesIgnoresPlainProse() {
        #expect(NoteTextStyler.linkRanges(in: "Buy the plane tickets").isEmpty)
        #expect(NoteTextStyler.linkRanges(in: "Lorem ipsum dolor sit amet consectetur").isEmpty)
    }

    @Test func linkRangesFindsLinkMidSentence() {
        let text = "Book it at https://loremipsum.com today"
        let ranges = NoteTextStyler.linkRanges(in: text)
        #expect(ranges.count == 1)
        #expect(ranges.first == NSRange(location: 11, length: 22))
    }

    @Test func linkRangesFindsMultipleLinks() {
        let text = "https://loremipsum.com\nwww.loremipsum.com"
        #expect(NoteTextStyler.linkRanges(in: text).count == 2)
    }

    @Test func linkRangesDetectsLinkInsideTitle() {
        // Links can be added anywhere, including the title line.
        let ranges = NoteTextStyler.linkRanges(in: "See loremipsum.com\nbody")
        #expect(ranges.count == 1)
        #expect(ranges.first == NSRange(location: 4, length: 14))
    }

    // MARK: Applied attributes

    @Test func applyAssignsTitleAndBodyFonts() {
        let storage = NSTextStorage(string: "Buy the plane tickets\nLorem ipsum")
        NoteTextStyler.apply(to: storage)

        let titleFont = storage.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        let bodyFont = storage.attribute(.font, at: 25, effectiveRange: nil) as? UIFont

        #expect(titleFont == AppFont.uiFont(.title))
        #expect(bodyFont == AppFont.uiFont(.body))
        #expect(titleFont != bodyFont)
    }

    @Test func applyUnderlinesLinks() {
        let storage = NSTextStorage(string: "Book it at https://loremipsum.com today")
        NoteTextStyler.apply(to: storage)

        let underlineAtLink = storage.attribute(.underlineStyle, at: 11, effectiveRange: nil) as? Int
        let underlineAtProse = storage.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int

        #expect(underlineAtLink == NSUnderlineStyle.single.rawValue)
        #expect(underlineAtProse == nil || underlineAtProse == 0)
    }

    @Test func applyKeepsLinkAtTitleSize() {
        // Underlining a link must not shrink it out of the title line.
        let storage = NSTextStorage(string: "loremipsum.com\nbody")
        NoteTextStyler.apply(to: storage)

        let linkFont = storage.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(linkFont == AppFont.uiFont(.title))
    }

    @Test func applyLeavesLinksInTheBodyColor() {
        // The preview colors its links; the editor deliberately does not, so a
        // link reads as ordinary text you can put the caret into.
        let storage = NSTextStorage(string: "Title\nBook at https://loremipsum.com")
        NoteTextStyler.apply(to: storage)

        let atLink = storage.attribute(.foregroundColor, at: 20, effectiveRange: nil) as? UIColor
        let atProse = storage.attribute(.foregroundColor, at: 6, effectiveRange: nil) as? UIColor
        #expect(atLink == atProse)

        let light = UITraitCollection(userInterfaceStyle: .light)
        let accent = UIColor(Material.Text.accent).resolvedColor(with: light)
        #expect(atLink?.resolvedColor(with: light) != accent)
    }

    @Test func applyIsIdempotent() {
        let text = "Buy the plane tickets\nBook at https://loremipsum.com"
        let once = NSTextStorage(string: text)
        NoteTextStyler.apply(to: once)

        let twice = NSTextStorage(string: text)
        NoteTextStyler.apply(to: twice)
        NoteTextStyler.apply(to: twice)

        #expect(once.isEqual(to: twice))
    }

    @Test func applyToEmptyStorageDoesNotCrash() {
        let storage = NSTextStorage(string: "")
        NoteTextStyler.apply(to: storage)
        #expect(storage.length == 0)
    }

    @Test func applyStylesEveryBodyParagraph() {
        let storage = NSTextStorage(string: "Title\nfirst body\nsecond body")
        NoteTextStyler.apply(to: storage)

        let secondParagraph = storage.attribute(.font, at: 20, effectiveRange: nil) as? UIFont
        #expect(secondParagraph == AppFont.uiFont(.body))
    }
}
