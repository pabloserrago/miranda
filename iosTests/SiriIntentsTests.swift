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

// MARK: - ShowTopPriorityIntent Tests

struct ShowTopPriorityIntentTests {

    @Test func returnsTopPriorityText() {
        let defaults = makeTestDefaults()
        let card = makeCard(text: "Top thing")
        seed(cards: [card], priorityIds: [card.id], in: defaults)

        let result = ShowTopPriorityIntent.topPriorityText(from: defaults)

        #expect(result == "Top thing")
    }

    @Test func respectsPriorityOrdering() {
        let defaults = makeTestDefaults()
        let first = makeCard(text: "First in priority list")
        let second = makeCard(text: "Second in priority list")
        // second is listed first in priorityIds — it should be returned
        seed(cards: [first, second], priorityIds: [second.id, first.id], in: defaults)

        let result = ShowTopPriorityIntent.topPriorityText(from: defaults)

        #expect(result == "Second in priority list")
    }

    @Test func skipsExcludedCardsAndReturnsNextActive() {
        let defaults = makeTestDefaults()
        let excluded = makeCard(text: "Excluded")
        let active = makeCard(text: "Active")
        seed(
            cards: [excluded, active],
            priorityIds: [excluded.id, active.id],
            excludedIds: [excluded.id],
            in: defaults
        )

        let result = ShowTopPriorityIntent.topPriorityText(from: defaults)

        #expect(result == "Active")
    }

    @Test func returnsNilWhenPriorityListIsEmpty() {
        let defaults = makeTestDefaults()
        let card = makeCard(text: "Not a priority")
        seed(cards: [card], priorityIds: [], in: defaults)

        let result = ShowTopPriorityIntent.topPriorityText(from: defaults)

        #expect(result == nil)
    }

    @Test func returnsNilWhenAllPrioritiesAreExcluded() {
        let defaults = makeTestDefaults()
        let card = makeCard(text: "Excluded priority")
        seed(cards: [card], priorityIds: [card.id], excludedIds: [card.id], in: defaults)

        let result = ShowTopPriorityIntent.topPriorityText(from: defaults)

        #expect(result == nil)
    }

    @Test func returnsNilOnEmptyDefaults() {
        let result = ShowTopPriorityIntent.topPriorityText(from: makeTestDefaults())

        #expect(result == nil)
    }
}

// MARK: - CompleteTopPriorityIntent Tests

struct CompleteTopPriorityIntentTests {

    @Test func returnsTextOfCompletedCard() {
        let defaults = makeTestDefaults()
        let card = makeCard(text: "Top priority")
        seed(cards: [card], priorityIds: [card.id], in: defaults)

        let result = CompleteTopPriorityIntent.completeTopPriority(in: defaults)

        #expect(result == "Top priority")
    }

    @Test func removesCardFromCards() {
        let defaults = makeTestDefaults()
        let card = makeCard(text: "Remove me")
        seed(cards: [card], priorityIds: [card.id], in: defaults)

        CompleteTopPriorityIntent.completeTopPriority(in: defaults)

        #expect(readCards(from: defaults).isEmpty)
    }

    @Test func removesCardFromPriorityIds() {
        let defaults = makeTestDefaults()
        let card = makeCard(text: "Remove me")
        seed(cards: [card], priorityIds: [card.id], in: defaults)

        CompleteTopPriorityIntent.completeTopPriority(in: defaults)

        #expect(!readPriorityIds(from: defaults).contains(card.id))
    }

    @Test func onlyRemovesTopPriorityLeavingOthersIntact() {
        let defaults = makeTestDefaults()
        let top = makeCard(text: "Top")
        let second = makeCard(text: "Second")
        seed(cards: [top, second], priorityIds: [top.id, second.id], in: defaults)

        CompleteTopPriorityIntent.completeTopPriority(in: defaults)

        let remainingCards = readCards(from: defaults)
        let remainingPriorityIds = readPriorityIds(from: defaults)
        #expect(remainingCards.count == 1)
        #expect(remainingCards.first?.simplifiedText == "Second")
        #expect(remainingPriorityIds == [second.id])
    }

    @Test func skipsExcludedTopAndCompletesFirstActiveCard() {
        let defaults = makeTestDefaults()
        let excluded = makeCard(text: "Excluded top")
        let active = makeCard(text: "Active second")
        seed(
            cards: [excluded, active],
            priorityIds: [excluded.id, active.id],
            excludedIds: [excluded.id],
            in: defaults
        )

        let result = CompleteTopPriorityIntent.completeTopPriority(in: defaults)

        #expect(result == "Active second")
        let remaining = readCards(from: defaults)
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == excluded.id)
    }

    @Test func returnsNilWhenNoPrioritiesExist() {
        let result = CompleteTopPriorityIntent.completeTopPriority(in: makeTestDefaults())

        #expect(result == nil)
    }

    @Test func returnsNilWhenAllPrioritiesAreExcluded() {
        let defaults = makeTestDefaults()
        let card = makeCard(text: "Excluded")
        seed(cards: [card], priorityIds: [card.id], excludedIds: [card.id], in: defaults)

        let result = CompleteTopPriorityIntent.completeTopPriority(in: defaults)

        #expect(result == nil)
        #expect(readCards(from: defaults).count == 1)
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
