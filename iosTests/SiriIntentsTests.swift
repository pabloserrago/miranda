import Foundation
import Testing
@testable import ios

// MARK: - Helpers

private func makeTestDefaults() -> UserDefaults {
    let suite = "com.test.SiriIntents.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return defaults
}

private func makeCard(text: String = "Test") -> Card {
    Card(originalText: text, simplifiedText: text, emoji: nil, timestamp: Date())
}

private func seed(
    cards: [Card],
    priorityIds: [UUID],
    excludedIds: [UUID] = [],
    in defaults: UserDefaults
) {
    defaults.set(try? JSONEncoder().encode(cards), forKey: "cards")
    defaults.set(priorityIds.map { $0.uuidString }, forKey: "priorityCardIds")
    defaults.set(excludedIds.map { $0.uuidString }, forKey: "excludedFromPriorityIds")
}

private func readCards(from defaults: UserDefaults) -> [Card] {
    guard let data = defaults.data(forKey: "cards"),
          let cards = try? JSONDecoder().decode([Card].self, from: data) else { return [] }
    return cards
}

private func readPriorityIds(from defaults: UserDefaults) -> [UUID] {
    (defaults.array(forKey: "priorityCardIds") as? [String] ?? []).compactMap { UUID(uuidString: $0) }
}

// MARK: - CaptureNoteIntent Tests

struct CaptureNoteIntentTests {

    @Test func savesDictatedNote() {
        let defaults = makeTestDefaults()
        let card = makeCard(text: "Buy milk")

        CaptureNoteIntent.capture(card, in: defaults)

        #expect(readCards(from: defaults) == [card])
    }

    @Test func fillsAnAvailablePrioritySlot() {
        let defaults = makeTestDefaults()
        let existing = makeCard(text: "Existing")
        seed(cards: [existing], priorityIds: [existing.id], in: defaults)
        let dictated = makeCard(text: "Dictated")

        CaptureNoteIntent.capture(dictated, in: defaults)

        #expect(readPriorityIds(from: defaults) == [existing.id, dictated.id])
    }

    @Test func keepsNoteButDoesNotExceedThreeActivePriorities() {
        let defaults = makeTestDefaults()
        let priorities = [makeCard(text: "One"), makeCard(text: "Two"), makeCard(text: "Three")]
        seed(cards: priorities, priorityIds: priorities.map(\.id), in: defaults)
        let dictated = makeCard(text: "Saved for later")

        CaptureNoteIntent.capture(dictated, in: defaults)

        #expect(readCards(from: defaults).contains(dictated))
        #expect(readPriorityIds(from: defaults) == priorities.map(\.id))
    }
}

// MARK: - RemoveAllPrioritiesIntent Tests

struct RemoveAllPrioritiesIntentTests {

    @Test func keepsEveryNote() {
        let defaults = makeTestDefaults()
        let cards = [makeCard(text: "One"), makeCard(text: "Two")]
        seed(cards: cards, priorityIds: cards.map(\.id), in: defaults)

        RemoveAllPrioritiesIntent.removeAllPriorities(in: defaults)

        #expect(readCards(from: defaults) == cards)
    }

    @Test func excludesEveryNoteFromPriorities() {
        let defaults = makeTestDefaults()
        let cards = [makeCard(text: "One"), makeCard(text: "Two")]
        seed(cards: cards, priorityIds: cards.map(\.id), in: defaults)

        let count = RemoveAllPrioritiesIntent.removeAllPriorities(in: defaults)

        let excluded = Set(
            (defaults.array(forKey: "excludedFromPriorityIds") as? [String] ?? [])
                .compactMap(UUID.init(uuidString:))
        )
        #expect(count == 2)
        #expect(excluded == Set(cards.map(\.id)))
    }

    @Test func preservesExistingExclusionsAndReportsOnlyActiveNotes() {
        let defaults = makeTestDefaults()
        let excluded = makeCard(text: "Already off")
        let active = makeCard(text: "Still on")
        seed(
            cards: [excluded, active],
            priorityIds: [excluded.id, active.id],
            excludedIds: [excluded.id],
            in: defaults
        )

        let count = RemoveAllPrioritiesIntent.removeAllPriorities(in: defaults)

        #expect(count == 1)
        #expect(readCards(from: defaults) == [excluded, active])
    }

    @Test func reportsZeroWhenThereAreNoNotes() {
        #expect(RemoveAllPrioritiesIntent.removeAllPriorities(in: makeTestDefaults()) == 0)
    }
}

// MARK: - CaptureAndPrioritizeIntent Tests

struct CaptureAndPrioritizeIntentTests {

    @Test func insertsCardAsPriorityWhenListIsEmpty() {
        let defaults = makeTestDefaults()
        let card = makeCard(text: "New priority")

        CaptureAndPrioritizeIntent.insertAsPriority(card, in: defaults)

        let priorityIds = readPriorityIds(from: defaults)
        #expect(priorityIds.first == card.id)
    }

    @Test func insertsCardAtFrontOfExistingPriorities() {
        let defaults = makeTestDefaults()
        let existing = makeCard(text: "Existing")
        seed(cards: [existing], priorityIds: [existing.id], in: defaults)

        let newCard = makeCard(text: "New top")
        CaptureAndPrioritizeIntent.insertAsPriority(newCard, in: defaults)

        let priorityIds = readPriorityIds(from: defaults)
        #expect(priorityIds.first == newCard.id)
        #expect(priorityIds.contains(existing.id))
    }

    @Test func addsCardToAllCards() {
        let defaults = makeTestDefaults()
        let card = makeCard(text: "My priority")

        CaptureAndPrioritizeIntent.insertAsPriority(card, in: defaults)

        let allCards = readCards(from: defaults)
        #expect(allCards.contains(where: { $0.id == card.id }))
    }

    @Test func evictsOldestActivePriorityWhenFull() {
        let defaults = makeTestDefaults()
        let oldest = makeCard(text: "Oldest")
        let middle = makeCard(text: "Middle")
        let newest = makeCard(text: "Newest")
        seed(cards: [oldest, middle, newest], priorityIds: [oldest.id, middle.id, newest.id], in: defaults)

        let forced = makeCard(text: "Force in")
        CaptureAndPrioritizeIntent.insertAsPriority(forced, in: defaults)

        let priorityIds = readPriorityIds(from: defaults)
        #expect(priorityIds.first == forced.id)
        #expect(!priorityIds.contains(oldest.id))
        #expect(priorityIds.contains(middle.id))
        #expect(priorityIds.contains(newest.id))
    }

    @Test func evictedCardRemainsInAllCards() {
        let defaults = makeTestDefaults()
        let oldest = makeCard(text: "Oldest")
        let middle = makeCard(text: "Middle")
        let newest = makeCard(text: "Newest")
        seed(cards: [oldest, middle, newest], priorityIds: [oldest.id, middle.id, newest.id], in: defaults)

        CaptureAndPrioritizeIntent.insertAsPriority(makeCard(text: "Force in"), in: defaults)

        let allCards = readCards(from: defaults)
        #expect(allCards.contains(where: { $0.id == oldest.id }))
        #expect(allCards.count == 4)
    }

    @Test func doesNotEvictWhenFewerThanThreeActivePriorities() {
        let defaults = makeTestDefaults()
        let a = makeCard(text: "A")
        let b = makeCard(text: "B")
        seed(cards: [a, b], priorityIds: [a.id, b.id], in: defaults)

        let c = makeCard(text: "C")
        CaptureAndPrioritizeIntent.insertAsPriority(c, in: defaults)

        let priorityIds = readPriorityIds(from: defaults)
        #expect(priorityIds.contains(a.id))
        #expect(priorityIds.contains(b.id))
        #expect(priorityIds.contains(c.id))
        #expect(priorityIds.count == 3)
    }

    @Test func excludedPrioritiesAreNotCountedTowardLimit() {
        // If 2 active + 1 excluded = 3 total, a new card should be added without eviction
        let defaults = makeTestDefaults()
        let excluded = makeCard(text: "Excluded")
        let a = makeCard(text: "A")
        let b = makeCard(text: "B")
        seed(
            cards: [excluded, a, b],
            priorityIds: [excluded.id, a.id, b.id],
            excludedIds: [excluded.id],
            in: defaults
        )

        let newCard = makeCard(text: "New")
        CaptureAndPrioritizeIntent.insertAsPriority(newCard, in: defaults)

        let priorityIds = readPriorityIds(from: defaults)
        #expect(priorityIds.contains(a.id))
        #expect(priorityIds.contains(b.id))
        #expect(priorityIds.contains(newCard.id))
    }
}
