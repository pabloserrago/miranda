import Foundation
import Testing
@testable import ios

// MARK: - Helpers

/// Isolated UserDefaults suite so tests don't pollute shared defaults.
private func makeTestDefaults() -> UserDefaults {
    let suite = "com.test.ReviewManager.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return defaults
}

/// A ReviewManager variant that injects test doubles for UserDefaults and
/// skips the WidgetCenter/Analytics calls so tests are fast and deterministic.
final class TestableReviewManager {

    private let defaults: UserDefaults

    // Injected values that replace async checks
    var simulatedHasWidget: Bool = false
    var simulatedCompletedCards: Int = 0
    var simulatedTotalAppOpens: Int = 0

    init(defaults: UserDefaults = makeTestDefaults()) {
        self.defaults = defaults
    }

    private enum Keys {
        static let shownCount = "reviewPromptShownCount"
        static let firstShownDate = "reviewPromptFirstShownDate"
        static let lastShownDate = "reviewPromptLastShownDate"
        static let lastShownOpenCount = "reviewPromptLastShownOpenCount"
        static let userHasRated = "reviewUserHasRated"
    }

    private let maxPrompts = 3
    private let minSessionGrowth = 3

    var shownCount: Int { defaults.integer(forKey: Keys.shownCount) }
    var currentAttemptNumber: Int { shownCount + 1 }

    func shouldShowPrompt() -> Bool {
        guard !defaults.bool(forKey: Keys.userHasRated) else { return false }
        guard shownCount < maxPrompts else { return false }
        guard isInvested() else { return false }
        return passesTimingGate()
    }

    func recordPromptShown() {
        let now = Date()
        if defaults.object(forKey: Keys.firstShownDate) == nil {
            defaults.set(now, forKey: Keys.firstShownDate)
        }
        defaults.set(shownCount + 1, forKey: Keys.shownCount)
        defaults.set(now, forKey: Keys.lastShownDate)
        defaults.set(simulatedTotalAppOpens, forKey: Keys.lastShownOpenCount)
    }

    func recordUserRated() {
        defaults.set(true, forKey: Keys.userHasRated)
    }

    /// Simulate time passing since first prompt, without changing real system clock.
    func backdateFirstShownDate(by days: Int) {
        let past = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        defaults.set(past, forKey: Keys.firstShownDate)
    }

    private func isInvested() -> Bool {
        simulatedHasWidget || simulatedCompletedCards >= 3
    }

    private func passesTimingGate() -> Bool {
        guard let firstShownDate = defaults.object(forKey: Keys.firstShownDate) as? Date else {
            return true
        }
        let daysSinceFirst = Calendar.current.dateComponents([.day], from: firstShownDate, to: Date()).day ?? 0
        let lastShownOpenCount = defaults.integer(forKey: Keys.lastShownOpenCount)
        let sessionsSinceLast = simulatedTotalAppOpens - lastShownOpenCount

        switch shownCount {
        case 1:
            return daysSinceFirst >= 7 && sessionsSinceLast >= minSessionGrowth
        case 2:
            return daysSinceFirst >= 21 && sessionsSinceLast >= minSessionGrowth
        default:
            return false
        }
    }
}

// MARK: - Investment Gate Tests

struct ReviewManagerInvestmentTests {

    @Test func noWidgetNoCompletions_notInvested() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = false
        mgr.simulatedCompletedCards = 0
        #expect(mgr.shouldShowPrompt() == false)
    }

    @Test func widgetPresentUnlocksInvestment() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        #expect(mgr.shouldShowPrompt() == true)
    }

    @Test func threeCompletionsUnlocksInvestmentWithoutWidget() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = false
        mgr.simulatedCompletedCards = 3
        #expect(mgr.shouldShowPrompt() == true)
    }

    @Test func twoCompletionsAloneIsNotEnough() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = false
        mgr.simulatedCompletedCards = 2
        #expect(mgr.shouldShowPrompt() == false)
    }
}

// MARK: - First Prompt Tests

struct ReviewManagerFirstPromptTests {

    @Test func firstPromptFiresOnFirstEligibleTrigger() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        #expect(mgr.shouldShowPrompt() == true)
    }

    @Test func recordingPromptIncreasesShownCount() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        mgr.recordPromptShown()
        #expect(mgr.shownCount == 1)
    }

    @Test func afterFirstPromptSameSessionNoRepeat() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        mgr.simulatedTotalAppOpens = 1
        mgr.recordPromptShown()
        // Still in same batch of sessions — sessions haven't grown by 3
        #expect(mgr.shouldShowPrompt() == false)
    }
}

// MARK: - Re-ask Timing Tests

struct ReviewManagerReaskTimingTests {

    @Test func secondPromptRequires7DaysAndThreeSessions() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        mgr.simulatedTotalAppOpens = 5

        mgr.recordPromptShown()         // first prompt shown, opens = 5
        mgr.backdateFirstShownDate(by: 7)
        mgr.simulatedTotalAppOpens = 8  // 3 new sessions

        #expect(mgr.shouldShowPrompt() == true)
    }

    @Test func secondPromptBlockedBefore7Days() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        mgr.simulatedTotalAppOpens = 5

        mgr.recordPromptShown()
        mgr.backdateFirstShownDate(by: 6)   // only 6 days
        mgr.simulatedTotalAppOpens = 8

        #expect(mgr.shouldShowPrompt() == false)
    }

    @Test func secondPromptBlockedWithoutEnoughSessions() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        mgr.simulatedTotalAppOpens = 5

        mgr.recordPromptShown()
        mgr.backdateFirstShownDate(by: 7)
        mgr.simulatedTotalAppOpens = 7  // only 2 new sessions

        #expect(mgr.shouldShowPrompt() == false)
    }

    @Test func thirdPromptRequires21DaysAndThreeSessions() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        mgr.simulatedTotalAppOpens = 5

        // First prompt
        mgr.recordPromptShown()
        mgr.backdateFirstShownDate(by: 21)
        mgr.simulatedTotalAppOpens = 8

        // Second prompt
        mgr.recordPromptShown()
        mgr.simulatedTotalAppOpens = 11 // 3 more sessions

        #expect(mgr.shouldShowPrompt() == true)
    }

    @Test func thirdPromptBlockedBefore21Days() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        mgr.simulatedTotalAppOpens = 5

        mgr.recordPromptShown()
        mgr.backdateFirstShownDate(by: 20)   // only 20 days
        mgr.simulatedTotalAppOpens = 8

        mgr.recordPromptShown()
        mgr.simulatedTotalAppOpens = 11

        #expect(mgr.shouldShowPrompt() == false)
    }
}

// MARK: - Cap Tests

struct ReviewManagerCapTests {

    @Test func promptsStopAfterThree() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        mgr.simulatedTotalAppOpens = 0

        // Exhaust all 3 prompts
        mgr.recordPromptShown()                // count = 1
        mgr.backdateFirstShownDate(by: 21)
        mgr.simulatedTotalAppOpens = 3
        mgr.recordPromptShown()                // count = 2
        mgr.simulatedTotalAppOpens = 6
        mgr.recordPromptShown()                // count = 3

        mgr.simulatedTotalAppOpens = 100
        #expect(mgr.shouldShowPrompt() == false)
    }

    @Test func ratingStopsAllFuturePrompts() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        mgr.recordUserRated()
        #expect(mgr.shouldShowPrompt() == false)
    }
}

// MARK: - Attempt Number Tests

struct ReviewManagerAttemptNumberTests {

    @Test func attemptNumberStartsAtOne() {
        let mgr = TestableReviewManager()
        #expect(mgr.currentAttemptNumber == 1)
    }

    @Test func attemptNumberIncrementsAfterRecord() {
        let mgr = TestableReviewManager()
        mgr.simulatedHasWidget = true
        mgr.recordPromptShown()
        #expect(mgr.currentAttemptNumber == 2)
    }
}
