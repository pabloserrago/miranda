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
