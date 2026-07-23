import Foundation
import Testing
@testable import ios

struct CardTests {
    @Test func cardTrimsSimplifiedText() {
        let card = Card(
            originalText: "x",
            simplifiedText: "Search for a French restaurant\n",
            emoji: nil,
            timestamp: Date()
        )
        #expect(card.simplifiedText == "Search for a French restaurant")
        #expect(!card.simplifiedText.hasSuffix("\n"))
    }

    @Test func cardTrimsOriginalText() {
        let card = Card(
            originalText: "  Buy milk \n",
            simplifiedText: "Buy milk",
            emoji: nil,
            timestamp: Date()
        )
        #expect(card.originalText == "Buy milk")
    }

    @Test func cardDecodeTrimsText() throws {
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "originalText": "Search for a French restaurant\\n",
            "simplifiedText": "Search for a French restaurant\\n",
            "emoji": null,
            "timestamp": 0
        }
        """
        let decoder = JSONDecoder()
        let card = try decoder.decode(Card.self, from: Data(json.utf8))
        #expect(card.simplifiedText == "Search for a French restaurant")
        #expect(card.originalText == "Search for a French restaurant")
    }
}
