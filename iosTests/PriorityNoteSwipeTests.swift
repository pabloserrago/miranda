import Foundation
import Testing
@testable import ios

struct NoteSwipeLayoutTests {

    @Test func priorityActionsAreOnExpectedSides() {
        #expect(NoteSwipeLayout.priorityLeadingActionIDs == ["remove"])
        #expect(NoteSwipeLayout.priorityTrailingActionIDs == ["complete", "delete"])
    }

    @Test func recentActionsAreOnExpectedSides() {
        #expect(NoteSwipeLayout.recentLeadingActionIDs == ["priority"])
        #expect(NoteSwipeLayout.recentTrailingActionIDs == ["complete", "delete"])
    }

    @Test func priorityAndRecentShareSameTrailingActions() {
        #expect(NoteSwipeLayout.priorityTrailingActionIDs == NoteSwipeLayout.recentTrailingActionIDs)
    }
}

struct PriorityNoteActionsTests {

    @Test func excludeFromPriorityAddsCardOnce() {
        let cardId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let first = PriorityNoteActions.excludeFromPriority(cardId: cardId, excludedIds: [])
        let second = PriorityNoteActions.excludeFromPriority(cardId: cardId, excludedIds: first)
        #expect(first == [cardId])
        #expect(second == [cardId])
    }

    @Test func includeInPriorityRemovesExclusion() {
        let cardId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let excluded = PriorityNoteActions.excludeFromPriority(cardId: cardId, excludedIds: [])
        let restored = PriorityNoteActions.includeInPriority(cardId: cardId, excludedIds: excluded)
        #expect(restored.isEmpty)
    }

    @Test func removeCardRemovesFromCardsAndPriorityOrder() {
        let first = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let second = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let cards = [
            Card(id: first, originalText: "A", simplifiedText: "A", emoji: nil, timestamp: .now),
            Card(id: second, originalText: "B", simplifiedText: "B", emoji: nil, timestamp: .now)
        ]
        let updated = PriorityNoteActions.removeCard(id: first, from: cards, priorityIds: [first, second])
        #expect(updated.cards.map(\.id) == [second])
        #expect(updated.priorityIds == [second])
    }
}

struct NoteArchiveTests {
    private let now = Date(timeIntervalSince1970: 20_000_000)

    @Test func archiveKeepsOnlyLastNinetyDaysNewestFirst() {
        let recent = archivedNote(reason: .deleted, daysAgo: 2)
        let boundary = archivedNote(reason: .completed, daysAgo: 90)
        let expired = archivedNote(reason: .completed, daysAgo: 91)

        let result = NoteArchive.recent([boundary, expired, recent], now: now)

        #expect(result.map(\.id) == [recent.id, boundary.id])
    }

    @Test func completedFilterExcludesDeletedNotes() {
        let completed = archivedNote(reason: .completed, daysAgo: 1)
        let deleted = archivedNote(reason: .deleted, daysAgo: 2)

        #expect(NoteArchive.filtered([completed, deleted], completedOnly: false).count == 2)
        #expect(NoteArchive.filtered([completed, deleted], completedOnly: true) == [completed])
    }

    private func archivedNote(reason: ArchiveReason, daysAgo: Double) -> ArchivedNote {
        ArchivedNote(
            card: Card(
                originalText: reason.rawValue,
                simplifiedText: reason.rawValue,
                emoji: nil,
                timestamp: now
            ),
            reason: reason,
            archivedAt: now.addingTimeInterval(-daysAgo * 24 * 60 * 60)
        )
    }
}
