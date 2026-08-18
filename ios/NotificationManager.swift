import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let notificationsEnabledKey = "notificationsEnabled"

    // Called when the user turns the toggle ON: request full authorization
    // (shows the one-time iOS permission dialog so notifications can appear on
    // the lock screen), then immediately schedule the current priorities so the
    // daily digest registers without waiting for the next card edit. Awaiting
    // authorization first avoids a race where scheduling checks settings before
    // auth is granted. Delivery stays silent via .passive + no attached sound.
    func enableReminders(cards: [Card]) {
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
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

    // Schedule a silent lock screen notification ~10 seconds after priorities change.
    // Skipped if the user disabled notifications or there are no cards.
    func schedulePriorityUpdate(cards: [Card]) {
        Task {
            let gate = NotificationManager.shouldSchedule(
                userEnabled: isUserEnabled(),
                authorized: await isAuthorized(),
                cardsEmpty: cards.isEmpty
            )
            cancelPendingPriorityUpdate()
            guard gate else { return }
            let content = makeContent(title: NotificationManager.priorityUpdateTitle, cards: cards)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            await schedule(content: content, identifier: "priority-update", trigger: trigger)
        }
    }

    // Schedule (or reschedule) a repeating 9:00 am digest with the current top priorities.
    // Skipped if the user disabled notifications or there are no cards.
    func scheduleDailyDigest(cards: [Card]) {
        Task {
            let gate = NotificationManager.shouldSchedule(
                userEnabled: isUserEnabled(),
                authorized: await isAuthorized(),
                cardsEmpty: cards.isEmpty
            )
            center.removePendingNotificationRequests(withIdentifiers: ["daily-digest"])
            guard gate else { return }
            let content = makeContent(title: NotificationManager.dailyDigestTitle, cards: cards)
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
    // gate so it can be verified on demand. Still requires authorization to be
    // delivered by the system.
    func sendTestReminder(cards: [Card]) {
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            let content = makeContent(title: NotificationManager.priorityUpdateTitle, cards: cards)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            await schedule(content: content, identifier: "priority-update", trigger: trigger)
        }
    }
    #endif

    // MARK: — Internal (exposed for unit testing)

    // Pure gate for whether a priority notification should be scheduled.
    static func shouldSchedule(userEnabled: Bool,
                               authorized: Bool,
                               cardsEmpty: Bool) -> Bool {
        userEnabled && authorized && !cardsEmpty
    }

    static func formatBody(for cards: [Card]) -> String {
        cards.prefix(3).enumerated()
            .map { "\($0.offset + 1). \($0.element.simplifiedText)" }
            .joined(separator: "\n")
    }

    // Notification copy is presented by the system, not by SwiftUI, so it is
    // resolved through the catalog explicitly — a plain String literal passed
    // as an argument is never extracted for localization.
    static var priorityUpdateTitle: String {
        String(localized: "notification.priority_update.title",
               defaultValue: "Your priorities",
               comment: "Title of the silent reminder sent shortly after priorities change")
    }

    static var dailyDigestTitle: String {
        String(localized: "notification.daily_digest.title",
               defaultValue: "Good morning — your priorities",
               comment: "Title of the 9am daily digest notification")
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

    private func makeContent(title: String, cards: [Card]) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = NotificationManager.formatBody(for: cards)
        // .passive is the native "silent" level: appears in the lock screen
        // notification list without playing a sound or waking the screen.
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
