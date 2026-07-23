import Foundation
import WidgetKit

final class ReviewManager {
    static let shared = ReviewManager()
    private init() {}

    private enum Keys {
        static let shownCount = "reviewPromptShownCount"
        static let firstShownDate = "reviewPromptFirstShownDate"
        static let lastShownDate = "reviewPromptLastShownDate"
        static let lastShownOpenCount = "reviewPromptLastShownOpenCount"
        static let userHasRated = "reviewUserHasRated"
    }

    private let defaults = UserDefaults.standard
    private let maxPrompts = 3
    private let minSessionGrowth = 3

    // MARK: - Public API

    func shouldShowPrompt() async -> Bool {
        guard !defaults.bool(forKey: Keys.userHasRated) else { return false }
        guard shownCount < maxPrompts else { return false }
        guard await isInvested() else { return false }
        return passesTimingGate()
    }

    func recordPromptShown() {
        let now = Date()
        if defaults.object(forKey: Keys.firstShownDate) == nil {
            defaults.set(now, forKey: Keys.firstShownDate)
        }
        defaults.set(shownCount + 1, forKey: Keys.shownCount)
        defaults.set(now, forKey: Keys.lastShownDate)
        defaults.set(Analytics.shared.getCounter("total_app_opens"), forKey: Keys.lastShownOpenCount)
    }

    func recordUserRated() {
        defaults.set(true, forKey: Keys.userHasRated)
    }

    /// 1-based attempt number, for analytics labelling.
    var currentAttemptNumber: Int { shownCount + 1 }

    // MARK: - Private

    private(set) var shownCount: Int {
        get { defaults.integer(forKey: Keys.shownCount) }
        set { defaults.set(newValue, forKey: Keys.shownCount) }
    }

    private func isInvested() async -> Bool {
        if await hasAnyWidget() { return true }
        return Analytics.shared.getCounter("total_cards_completed") >= 3
    }

    private func hasAnyWidget() async -> Bool {
        guard let configs = try? await WidgetCenter.shared.currentConfigurations() else { return false }
        return !configs.isEmpty
    }

    private func passesTimingGate() -> Bool {
        guard let firstShownDate = defaults.object(forKey: Keys.firstShownDate) as? Date else {
            return true
        }
        let daysSinceFirst = Calendar.current.dateComponents([.day], from: firstShownDate, to: Date()).day ?? 0
        let lastShownOpenCount = defaults.integer(forKey: Keys.lastShownOpenCount)
        let sessionsSinceLast = Analytics.shared.getCounter("total_app_opens") - lastShownOpenCount

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
