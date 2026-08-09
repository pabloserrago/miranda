import Foundation
import Testing
@testable import ios

/// Covers splitting an *existing* note during Edit mode. Unlike creation, the
/// first resulting note must reuse the original note's identity (id, emoji,
/// timestamp) so it keeps its priority slot; the rest become brand-new notes.
struct NoteEditSplitTests {

    private func makeOriginal() -> Card {
        Card(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            originalText: "Groceries",
            simplifiedText: "Groceries",
            emoji: "🛒",
            timestamp: Date(timeIntervalSince1970: 1_000)
        )
    }

    @Test func applyEditSingleTextUpdatesOriginalOnly() {
        let original = makeOriginal()
        let result = NoteSplitter.applyEdit(to: original, splitTexts: ["Buy milk"])

        #expect(result != nil)
        #expect(result?.newCards.isEmpty == true)
        #expect(result?.updatedOriginal.id == original.id)
        #expect(result?.updatedOriginal.simplifiedText == "Buy milk")
        #expect(result?.updatedOriginal.originalText == "Buy milk")
        // Identity that must survive an edit.
        #expect(result?.updatedOriginal.emoji == original.emoji)
        #expect(result?.updatedOriginal.timestamp == original.timestamp)
    }

    @Test func applyEditPreservesOriginalAndAppendsRest() {
        let original = makeOriginal()
        let result = NoteSplitter.applyEdit(to: original, splitTexts: ["milk", "eggs", "bread"])

        // First segment keeps the original's identity.
        #expect(result?.updatedOriginal.id == original.id)
        #expect(result?.updatedOriginal.simplifiedText == "milk")
        #expect(result?.updatedOriginal.emoji == original.emoji)
        #expect(result?.updatedOriginal.timestamp == original.timestamp)

        // The rest become new notes with fresh identities and no emoji.
        #expect(result?.newCards.count == 2)
        #expect(result?.newCards.map(\.simplifiedText) == ["eggs", "bread"])
        #expect(result?.newCards.allSatisfy { $0.id != original.id } == true)
        #expect(result?.newCards.allSatisfy { $0.emoji == nil } == true)
    }

    @Test func applyEditPreservesOrder() {
        let original = makeOriginal()
        let result = NoteSplitter.applyEdit(to: original, splitTexts: ["one", "two", "three", "four"])
        let ordered = [result?.updatedOriginal.simplifiedText] + (result?.newCards.map(\.simplifiedText) ?? [])
        #expect(ordered == ["one", "two", "three", "four"])
    }

    @Test func applyEditEmptyReturnsNil() {
        let original = makeOriginal()
        #expect(NoteSplitter.applyEdit(to: original, splitTexts: []) == nil)
    }
}
