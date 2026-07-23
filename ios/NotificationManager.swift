import UserNotifications
import WidgetKit

final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let notificationsEnabledKey = "notificationsEnabled"

    // Called when the user turns the toggle ON in Miranda Settings.
    // Provisional authorization is granted silently — no system dialog shown.
    func requestProvisionalAuthorization() {
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
        }
    }

    // Called when the user turns the toggle ON: request authorization, then
    // immediately schedule the current priorities so the daily digest registers
    // without waiting for the next card edit. Awaiting authorization first avoids
    // a race where scheduling checks settings before auth is granted.
    func enableReminders(cards: [Card]) {
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
            schedulePriorityUpdate(cards: cards)
            scheduleDailyDigest(cards: cards)
        }
    }

    // Call on app foreground to stay in sync if the user revoked authorization
    // from iOS Settings or tapped "Turn Off" in Notification Center.
    func syncAuthorizationStatus() {
        Task {
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .denied {
                UserDefaults.standard.set(false, forKey: notificationsEnabledKey)
                cancelAllNotifications()
            }
        }
    }

    // Schedule a quiet Notification Center entry ~10 seconds after priorities change.
    // Skipped if the user disabled notifications or the lock screen widget is active.
    func schedulePriorityUpdate(cards: [Card]) {
        Task {
            let gate = NotificationManager.shouldSchedule(
                userEnabled: isUserEnabled(),
                authorized: await isAuthorized(),
                hasLockScreenWidget: await hasActiveLockScreenWidget(),
                cardsEmpty: cards.isEmpty
            )
            cancelPendingPriorityUpdate()
            guard gate else { return }
            let content = makeContent(title: "Your priorities", cards: cards)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            await schedule(content: content, identifier: "priority-update", trigger: trigger)
        }
    }

    // Schedule (or reschedule) a repeating 9:00 am digest with the current top priorities.
    // Skipped if the user disabled notifications or the lock screen widget is active.
    func scheduleDailyDigest(cards: [Card]) {
        Task {
            let gate = NotificationManager.shouldSchedule(
                userEnabled: isUserEnabled(),
                authorized: await isAuthorized(),
                hasLockScreenWidget: await hasActiveLockScreenWidget(),
                cardsEmpty: cards.isEmpty
            )
            center.removePendingNotificationRequests(withIdentifiers: ["daily-digest"])
            guard gate else { return }
            let content = makeContent(title: "Good morning — your priorities", cards: cards)
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            await schedule(content: content, identifier: "daily-digest", trigger: trigger)
        }
    }

    // Cancel all Miranda notifications — called when user turns the toggle OFF.
    func cancelAllNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: ["priority-update", "daily-digest"])
    }

    #if DEBUG
    // Debug-only: fire a priority reminder ~3s from now, bypassing the enabled
    // and lock-screen-widget gates so it can be verified on demand. Still requires
    // (provisional) authorization to be delivered by the system.
    func sendTestReminder(cards: [Card]) {
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
            let content = makeContent(title: "Your priorities", cards: cards)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            await schedule(content: content, identifier: "priority-update", trigger: trigger)
        }
    }
    #endif

    // MARK: — Internal (exposed for unit testing)

    // Pure gate for whether a priority notification should be scheduled.
    static func shouldSchedule(userEnabled: Bool,
                               authorized: Bool,
                               hasLockScreenWidget: Bool,
                               cardsEmpty: Bool) -> Bool {
        userEnabled && authorized && !hasLockScreenWidget && !cardsEmpty
    }

    static func formatBody(for cards: [Card]) -> String {
        cards.prefix(3).enumerated()
            .map { "\($0.offset + 1). \($0.element.simplifiedText)" }
            .joined(separator: "\n")
    }

    // MARK: — Private

    private func isUserEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: notificationsEnabledKey)
    }

    private func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    private func hasActiveLockScreenWidget() async -> Bool {
        guard let configs = try? await WidgetCenter.shared.currentConfigurations() else { return false }
        return configs.contains {
            $0.family == .accessoryRectangular || $0.family == .accessoryInline
        }
    }

    private func makeContent(title: String, cards: [Card]) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = NotificationManager.formatBody(for: cards)
        content.interruptionLevel = .passive
        return content
    }

    private func schedule(content: UNMutableNotificationContent,
                          identifier: String,
                          trigger: UNNotificationTrigger) async {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func cancelPendingPriorityUpdate() {
        center.removePendingNotificationRequests(withIdentifiers: ["priority-update"])
    }
}
