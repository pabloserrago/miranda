import Foundation
import Testing
@testable import ios

// MARK: - Helpers

private func makeCard(_ simplified: String) -> Card {
    Card(originalText: simplified, simplifiedText: simplified, emoji: nil, timestamp: Date())
}

// MARK: - formatBody

struct NotificationManagerFormatBodyTests {

    @Test func emptyCardsProduceEmptyBody() {
        #expect(NotificationManager.formatBody(for: []) == "")
    }

    @Test func singleCardIsNumberedOne() {
        let body = NotificationManager.formatBody(for: [makeCard("Call dentist")])
        #expect(body == "1. Call dentist")
    }

    @Test func threeCardsAreNumberedAndNewlineJoined() {
        let body = NotificationManager.formatBody(for: [
            makeCard("First"),
            makeCard("Second"),
            makeCard("Third"),
        ])
        #expect(body == "1. First\n2. Second\n3. Third")
    }

    @Test func moreThanThreeCardsAreTruncatedToThree() {
        let body = NotificationManager.formatBody(for: [
            makeCard("First"),
            makeCard("Second"),
            makeCard("Third"),
            makeCard("Fourth"),
        ])
        #expect(body == "1. First\n2. Second\n3. Third")
        #expect(!body.contains("Fourth"))
    }

    @Test func usesSimplifiedTextNotOriginalText() {
        let card = Card(originalText: "the original long text",
                        simplifiedText: "simplified",
                        emoji: nil,
                        timestamp: Date())
        #expect(NotificationManager.formatBody(for: [card]) == "1. simplified")
    }
}

// MARK: - shouldSchedule

struct NotificationManagerShouldScheduleTests {

    @Test func allConditionsMetSchedules() {
        #expect(NotificationManager.shouldSchedule(
            userEnabled: true, authorized: true, hasLockScreenWidget: false, cardsEmpty: false) == true)
    }

    @Test func disabledByUserDoesNotSchedule() {
        #expect(NotificationManager.shouldSchedule(
            userEnabled: false, authorized: true, hasLockScreenWidget: false, cardsEmpty: false) == false)
    }

    @Test func unauthorizedDoesNotSchedule() {
        #expect(NotificationManager.shouldSchedule(
            userEnabled: true, authorized: false, hasLockScreenWidget: false, cardsEmpty: false) == false)
    }

    @Test func lockScreenWidgetSuppressesSchedule() {
        #expect(NotificationManager.shouldSchedule(
            userEnabled: true, authorized: true, hasLockScreenWidget: true, cardsEmpty: false) == false)
    }

    @Test func noCardsDoesNotSchedule() {
        #expect(NotificationManager.shouldSchedule(
            userEnabled: true, authorized: true, hasLockScreenWidget: false, cardsEmpty: true) == false)
    }
}
