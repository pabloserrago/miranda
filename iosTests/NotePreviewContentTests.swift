import Foundation
import SwiftUI
import Testing
@testable import ios

/// Covers how a saved note is laid out for reading. The editor and the preview
/// agree that the first line is the title, but they part ways on links: the
/// editor only underlines them so a tap can place the caret, while the preview
/// colors them and makes them open.
struct NotePreviewContentTests {

    // MARK: Title and paragraphs

    @Test func titleOnlyNoteHasNoParagraphs() {
        let content = NotePreviewContent(text: "Buy the plane ticket")
        #expect(content.title == "Buy the plane ticket")
        #expect(content.paragraphs.isEmpty)
    }

    @Test func firstLineIsTheTitleAndTheRestAreParagraphs() {
        let content = NotePreviewContent(
            text: "Buy the plane ticket\nLorem ipsum dolor sit amet.\nhttps://loremipsum.com"
        )
        #expect(content.title == "Buy the plane ticket")
        #expect(content.paragraphs == ["Lorem ipsum dolor sit amet.", "https://loremipsum.com"])
    }

    @Test func blankLinesBetweenParagraphsAreDropped() {
        // Typing a blank line between paragraphs is spacing intent, not content;
        // the preview supplies the spacing itself.
        let content = NotePreviewContent(text: "Title\n\nfirst\n\n\nsecond\n")
        #expect(content.paragraphs == ["first", "second"])
    }

    @Test func surroundingWhitespaceIsTrimmed() {
        let content = NotePreviewContent(text: "  Buy the plane ticket  \n  Lorem ipsum.  ")
        #expect(content.title == "Buy the plane ticket")
        #expect(content.paragraphs == ["Lorem ipsum."])
    }

    @Test func emptyNoteHasEmptyTitle() {
        let content = NotePreviewContent(text: "   \n  ")
        #expect(content.title.isEmpty)
        #expect(content.paragraphs.isEmpty)
    }

    @Test func selectableTextContainsTheWholeNoteInOneValue() {
        let content = NotePreviewContent(
            text: "https://tickets.example\nLorem ipsum dolor sit amet.\nhttps://loremipsum.com"
        )

        #expect(
            String(content.selectableText.characters)
                == "https://tickets.example\n\nLorem ipsum dolor sit amet.\n\nhttps://loremipsum.com"
        )
        #expect(content.selectableText.runs.compactMap(\.link).count == 2)
    }

    // MARK: Link runs

    @Test func linkRunCarriesAccentColorAndUnderline() {
        let attributed = NotePreviewContent.attributed("Book at https://loremipsum.com today")

        let linkRuns = attributed.runs.filter { $0.link != nil }
        #expect(linkRuns.count == 1)
        #expect(linkRuns.first?.foregroundColor == Material.Text.accent)
        #expect(linkRuns.first?.underlineStyle != nil)
    }

    @Test func proseRunsAreLeftUnstyled() {
        // The surrounding Text supplies the body face, so prose must not carry
        // its own color — otherwise the title face could not reuse this.
        let attributed = NotePreviewContent.attributed("Book at https://loremipsum.com today")

        let prose = attributed.runs.filter { $0.link == nil }
        #expect(!prose.isEmpty)
        for run in prose {
            #expect(run.foregroundColor == nil)
            #expect(run.underlineStyle == nil)
        }
    }

    @Test func bareDomainBecomesAnAbsoluteURL() {
        // Typed without a scheme, it still has to be openable.
        let attributed = NotePreviewContent.attributed("loremipsum.com")
        let link = attributed.runs.compactMap(\.link).first

        #expect(link?.scheme != nil)
        #expect(link?.host == "loremipsum.com")
    }

    @Test func wwwFormBecomesAnAbsoluteURL() {
        let attributed = NotePreviewContent.attributed("www.loremipsum.com")
        let link = attributed.runs.compactMap(\.link).first

        #expect(link?.scheme != nil)
        #expect(link?.host == "www.loremipsum.com")
    }

    @Test func schemedURLIsKeptAsTyped() {
        let attributed = NotePreviewContent.attributed("https://loremipsum.com/flights")
        let link = attributed.runs.compactMap(\.link).first

        #expect(link?.absoluteString == "https://loremipsum.com/flights")
    }

    @Test func everyLinkOnALineIsStyled() {
        let attributed = NotePreviewContent.attributed(
            "https://one.com and www.two.com and three.com"
        )
        #expect(attributed.runs.compactMap(\.link).count == 3)
    }

    @Test func attributedTextWithoutLinksRoundTrips() {
        let paragraph = "Lorem ipsum dolor sit amet consectetur."
        let attributed = NotePreviewContent.attributed(paragraph)

        #expect(String(attributed.characters) == paragraph)
        #expect(attributed.runs.allSatisfy { $0.link == nil })
    }

    @Test func attributedTextPreservesTheWholeParagraph() {
        // Slicing around link ranges must not drop or reorder any text.
        let paragraph = "Book at https://loremipsum.com today, or www.two.com later"
        let attributed = NotePreviewContent.attributed(paragraph)

        #expect(String(attributed.characters) == paragraph)
    }

    @Test func attributedTextHandlesEmojiBeforeALink() {
        // Link ranges arrive as UTF-16 offsets, so a non-BMP emoji ahead of the
        // link would misalign a naive slice.
        let paragraph = "🛒 buy at loremipsum.com"
        let attributed = NotePreviewContent.attributed(paragraph)

        #expect(String(attributed.characters) == paragraph)
        let linkRun = attributed.runs.first { $0.link != nil }
        let linkText = linkRun.map { String(attributed[$0.range].characters) }
        #expect(linkText == "loremipsum.com")
    }
}
