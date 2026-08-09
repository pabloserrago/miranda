import Foundation
import Testing
@testable import ios

struct NoteSplitterTests {
    @Test func splitsHyphenLines() {
        #expect(NoteSplitter.split("- milk\n- eggs") == ["milk", "eggs"])
    }

    @Test func leadingTextBecomesOwnNote() {
        #expect(NoteSplitter.split("Groceries:\n- milk\n- eggs") == ["Groceries:", "milk", "eggs"])
    }

    @Test func noHyphensReturnsSingleNote() {
        #expect(NoteSplitter.split("just a plain note") == ["just a plain note"])
    }

    @Test func continuationLinesAttach() {
        #expect(NoteSplitter.split("- milk\nwhole fat\n- eggs") == ["milk\nwhole fat", "eggs"])
    }

    @Test func dropsEmptyItems() {
        #expect(NoteSplitter.split("- milk\n-\n- \n\n- eggs") == ["milk", "eggs"])
        #expect(NoteSplitter.split("   \n") == [])
    }
}

struct HyphenSegmentEditorTests {
    @Test func commitAfterNewlineCommitsHyphenLine() {
        let result = NoteSplitter.commitAfterNewline("- milk\n")
        #expect(result.committed == ["milk"])
        #expect(result.remaining == "")
    }

    @Test func commitAfterNewlineIgnoresPlainLine() {
        let result = NoteSplitter.commitAfterNewline("plain text\n")
        #expect(result.committed == [])
        #expect(result.remaining == "plain text\n")
    }

    @Test func commitAfterNewlineRequiresTrailingNewline() {
        let result = NoteSplitter.commitAfterNewline("- milk")
        #expect(result.committed == [])
        #expect(result.remaining == "- milk")
    }

    @Test func commitAfterNewlineCommitsLeadingText() {
        let result = NoteSplitter.commitAfterNewline("Groceries:\n- milk\n")
        #expect(result.committed == ["Groceries:", "milk"])
        #expect(result.remaining == "")
    }

    @Test func canonicalTextRoundTrips() {
        let segments = ["milk", "whole eggs\nfree range"]
        let active = "- bread"
        let canonical = NoteSplitter.canonicalText(segments: segments, activeText: active)
        #expect(NoteSplitter.split(canonical) == segments + NoteSplitter.split(active))
    }

    @Test func canonicalTextPassthroughWithoutSegments() {
        #expect(NoteSplitter.canonicalText(segments: [], activeText: "just a note") == "just a note")
    }

    @Test func canonicalTextWithEmptyActiveText() {
        let canonical = NoteSplitter.canonicalText(segments: ["milk", "eggs"], activeText: "")
        #expect(NoteSplitter.split(canonical) == ["milk", "eggs"])
    }
}
