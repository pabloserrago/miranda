import Foundation

enum NoteSwipeLayout {
    /// Swipe right — actions on the left.
    static let priorityLeadingActionIDs = ["remove"]
    /// Swipe left — actions on the right.
    static let priorityTrailingActionIDs = ["complete", "delete"]
    static let recentLeadingActionIDs = ["priority"]
    static let recentTrailingActionIDs = ["complete", "delete"]
}

enum PriorityNoteActions {
    static func excludeFromPriority(cardId: UUID, excludedIds: [UUID]) -> [UUID] {
        guard !excludedIds.contains(cardId) else { return excludedIds }
        return excludedIds + [cardId]
    }

    static func includeInPriority(cardId: UUID, excludedIds: [UUID]) -> [UUID] {
        excludedIds.filter { $0 != cardId }
    }

    static func removeCard(id: UUID, from cards: [Card], priorityIds: [UUID]) -> (cards: [Card], priorityIds: [UUID]) {
        (
            cards.filter { $0.id != id },
            priorityIds.filter { $0 != id }
        )
    }
}

#if DEBUG
extension ContentView {
    static let uiTestSeedCards: [Card] = [
        Card(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            originalText: "Take medicine",
            simplifiedText: "Take medicine Take your medicine 💊",
            emoji: "💊",
            timestamp: Date(timeIntervalSince1970: 1_000)
        ),
        Card(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            originalText: "Water the plants",
            simplifiedText: "Water the plants 🪴",
            emoji: "🪴",
            timestamp: Date(timeIntervalSince1970: 2_000)
        ),
        Card(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            originalText: "Set an alarm",
            simplifiedText: "Set an alarm ⏰",
            emoji: "⏰",
            timestamp: Date(timeIntervalSince1970: 3_000)
        )
    ]

    static var isUITestLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestSeedNotes")
    }
}
#endif
