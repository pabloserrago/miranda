import Testing
@testable import ios

/// The first-launch onboarding gate: fresh installs see the flow, completed
/// or upgrading users never do, and UI-test launches control it explicitly.
struct OnboardingGateTests {

    @Test func freshInstallShowsOnboarding() {
        #expect(ContentView.shouldShowOnboarding(
            hasCompleted: false, hasPersistedCards: false, arguments: []
        ))
    }

    @Test func completedFlagHidesOnboarding() {
        #expect(!ContentView.shouldShowOnboarding(
            hasCompleted: true, hasPersistedCards: false, arguments: []
        ))
    }

    @Test func existingCardsHideOnboardingForUpgraders() {
        #expect(!ContentView.shouldShowOnboarding(
            hasCompleted: false, hasPersistedCards: true, arguments: []
        ))
    }

    @Test func uiTestLaunchesSuppressOnboarding() {
        #expect(!ContentView.shouldShowOnboarding(
            hasCompleted: false, hasPersistedCards: false, arguments: ["-UITestSeedNotes"]
        ))
        #expect(!ContentView.shouldShowOnboarding(
            hasCompleted: false, hasPersistedCards: false, arguments: ["-UITestHyphenSplit"]
        ))
    }

    @Test func explicitArgumentForcesOnboarding() {
        #expect(ContentView.shouldShowOnboarding(
            hasCompleted: true, hasPersistedCards: true, arguments: ["-UITestShowOnboarding"]
        ))
    }
}
