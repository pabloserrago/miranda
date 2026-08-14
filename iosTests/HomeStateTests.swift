import Foundation
import Testing
@testable import ios

/// Which of the three home screens renders, the 3-priority cap the Set
/// Priority sheet must respect, and the gate that re-offers the sheet after a
/// completion.
struct HomeStateTests {

    // MARK: - Home state

    @Test func noCardsShowsTheCaptureEmptyState() {
        #expect(ContentView.homeState(hasCards: false, hasPriorities: false) == .empty)
    }

    @Test func cardsWithoutPrioritiesShowsTheNoPriorityState() {
        #expect(ContentView.homeState(hasCards: true, hasPriorities: false) == .noPriority)
    }

    @Test func cardsWithPrioritiesShowsTheList() {
        #expect(ContentView.homeState(hasCards: true, hasPriorities: true) == .list)
    }

    // MARK: - Priority cap

    @Test func promotingIsAllowedBelowTheCap() {
        #expect(PriorityNoteActions.canPromoteToPriority(currentPriorityCount: 0))
        #expect(PriorityNoteActions.canPromoteToPriority(currentPriorityCount: 2))
    }

    @Test func promotingIsRefusedAtTheCap() {
        #expect(!PriorityNoteActions.canPromoteToPriority(currentPriorityCount: 3))
        #expect(!PriorityNoteActions.canPromoteToPriority(currentPriorityCount: 4))
    }

    @Test func promotingUnexcludesTheSelectedCardOnly() {
        let promoted = UUID()
        let other = UUID()
        let excluded = PriorityNoteActions.includeInPriority(
            cardId: promoted, excludedIds: [promoted, other]
        )
        #expect(excluded == [other])
    }

    // MARK: - Post-completion picker gate

    @Test func pickerIsOfferedWhenThereIsRoomAndCardsRemain() {
        #expect(ContentView.shouldOfferPicker(priorityCount: 0, cardsEmpty: false))
        #expect(ContentView.shouldOfferPicker(priorityCount: 2, cardsEmpty: false))
    }

    @Test func pickerIsNotOfferedWhenPrioritiesAreFull() {
        #expect(!ContentView.shouldOfferPicker(priorityCount: 3, cardsEmpty: false))
    }

    @Test func pickerIsNotOfferedWithoutCards() {
        #expect(!ContentView.shouldOfferPicker(priorityCount: 0, cardsEmpty: true))
    }
}
