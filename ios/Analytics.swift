import Foundation
import WidgetKit

// Lightweight analytics for tracking app usage
class Analytics {
    static let shared = Analytics()
    
    private let appVersion: String = AppInfo.shortVersion
    
    private let appLanguage: String = {
        Locale.current.language.languageCode?.identifier ?? "en"
    }()
    
    private init() {}
    
    // MARK: - Install Identity
    
    /// Anonymous, app-generated identifier for this install. It exists so
    /// events can be grouped per install (retention, cohorts, funnels) — it is
    /// not IDFA/IDFV, never leaves the App Group, and dies with the install.
    /// Lives in the App Group rather than `UserDefaults.standard` so the widget
    /// extension can attribute its own events under the same value.
    static let installIDKey = "analytics_install_id"
    
    /// Returns `stored` when it is a well-formed UUID, otherwise a fresh one.
    static func resolveInstallID(stored: String?) -> String {
        guard let stored, UUID(uuidString: stored) != nil else { return UUID().uuidString }
        return stored
    }
    
    /// Reads the install identifier, minting and persisting one on first call.
    static func installID(in defaults: UserDefaults = SharedCardManager.defaults) -> String {
        let stored = defaults.string(forKey: installIDKey)
        let resolved = resolveInstallID(stored: stored)
        if resolved != stored {
            defaults.set(resolved, forKey: installIDKey)
        }
        return resolved
    }
    
    // MARK: - Event Tracking
    
    func trackAppOpened() {
        logEvent("app_opened")
        incrementCounter("total_app_opens")
    }
    
    /// Logged in addition to `app_opened` when the launch came from a widget
    /// deep link. Kept as its own event rather than a property on `app_opened`
    /// because `onOpenURL` fires after `onAppear` on a cold launch, so the
    /// source is not yet known when `app_opened` is sent.
    func trackWidgetOpened(destination: String) {
        logEvent("widget_opened", properties: ["destination": destination])
        incrementCounter("total_widget_opens")
    }
    
    /// Which widget families this install currently has on a Home or Lock
    /// Screen. Logged only when the set changes, since it is polled on every
    /// foreground — pair it with `widget_opened` for frequency of use.
    func trackWidgetInventory(
        families: [String],
        in defaults: UserDefaults = SharedCardManager.defaults
    ) {
        let signature = Analytics.widgetInventorySignature(families: families)
        guard Analytics.consumeWidgetInventoryChange(signature: signature, in: defaults) else { return }
        logEvent("widget_inventory", properties: [
            "families": signature,
            "count": families.count
        ])
    }

    /// Asks WidgetKit what is installed. `getCurrentConfigurations` is
    /// completion-handler only, so it is bridged here. A failure is dropped
    /// rather than logged as "none": an unavailable extension is not the same
    /// as an empty Home Screen.
    func refreshWidgetInventory() async {
        let installed: [WidgetInfo]? = await withCheckedContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                continuation.resume(returning: try? result.get())
            }
        }
        guard let installed else { return }
        trackWidgetInventory(families: installed.map { String(describing: $0.family) })
    }

    /// Order-independent description of an installed set, so re-polling the same
    /// widgets in a different order does not read as a change.
    static func widgetInventorySignature(families: [String]) -> String {
        families.isEmpty ? "none" : Set(families).sorted().joined(separator: ",")
    }

    /// True the first time `signature` differs from the stored one, which it
    /// then becomes.
    static func consumeWidgetInventoryChange(signature: String, in defaults: UserDefaults) -> Bool {
        guard defaults.string(forKey: widgetInventoryKey) != signature else { return false }
        defaults.set(signature, forKey: widgetInventoryKey)
        return true
    }

    static let widgetInventoryKey = "analytics_widget_inventory"

    /// Siri, Shortcuts and Spotlight invocations. These run in the app's own
    /// process, so they log through the normal path.
    func trackIntentRun(_ intent: String) {
        logEvent("intent_run", properties: ["intent": intent])
    }

    /// Classifies a `miranda://` deep link, or `nil` when the URL is not one
    /// the widget emits.
    static func widgetDestination(for url: URL) -> String? {
        guard url.scheme == "miranda" else { return nil }
        switch url.host {
        case "card": return "card"
        case "capture": return "capture"
        default: return nil
        }
    }
    
    func trackOnboardingCompleted() {
        logEvent("onboarding_completed")
    }

    func trackCardCreated(hasEmoji: Bool) {
        logEvent("card_created", properties: [
            "has_emoji": hasEmoji,
            "hour_of_day": getCurrentHour(),
            "day_of_week": getCurrentDayOfWeek()
        ])
        incrementCounter("total_cards_created")
    }
    
    func trackCardCompleted(timeToComplete: TimeInterval) {
        logEvent("card_completed", properties: [
            "time_to_complete_minutes": Int(timeToComplete / 60),
            "hour_of_day": getCurrentHour(),
            "day_of_week": getCurrentDayOfWeek()
        ])
        incrementCounter("total_cards_completed")
    }
    
    func trackCardViewed() {
        logEvent("card_viewed_fullscreen")
    }
    
    func trackRandomCardGenerated() {
        logEvent("random_card_generated")
    }

    func trackReviewPromptShown(attempt: Int) {
        logEvent("review_prompt_shown", properties: ["attempt": attempt])
    }

    func trackReviewSentimentPositive() {
        logEvent("review_sentiment_positive")
    }

    func trackReviewSentimentNegative() {
        logEvent("review_sentiment_negative")
    }

    func trackReviewStoreOpened(source: String) {
        logEvent("review_store_opened", properties: ["source": source])
    }
    
    // MARK: - Statistics
    
    func getStats() -> [String: Any] {
        return [
            "total_app_opens": getCounter("total_app_opens"),
            "total_cards_created": getCounter("total_cards_created"),
            "total_cards_completed": getCounter("total_cards_completed"),
            "install_date": getInstallDate(),
            "days_since_install": getDaysSinceInstall()
        ]
    }
    
    // MARK: - Private Helpers
    
    private func logEvent(_ name: String, properties: [String: Any] = [:]) {
        var event: [String: Any] = [
            "event": name,
            "timestamp": Date().timeIntervalSince1970
        ]
        event.merge(properties) { _, new in new }
        
        // Save event to local storage
        var events = getEvents()
        events.append(event)
        
        // Keep only last 1000 events (lightweight)
        if events.count > 1000 {
            events = Array(events.suffix(1000))
        }
        
        saveEvents(events)
        
        // No-op unless the Supabase backend is enabled; otherwise analytics
        // stay strictly on-device (see PRIVACY.md).
        sendToSupabase(event: name, properties: properties)
        
        // Print to console for debugging
        print("📊 Analytics: \(name) - \(properties)")
    }
    
    private func sendToSupabase(event: String, properties: [String: Any]) {
        let body = Analytics.eventBody(
            event: event,
            properties: properties,
            appVersion: appVersion,
            language: appLanguage,
            installID: Analytics.installID())
        
        guard let request = Supabase.insertRequest(table: "analytics", body: body) else { return }
        
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }
    
    /// The row shape uploaded to the `analytics` table. `install_id` must exist
    /// as a column or PostgREST rejects the insert with 400.
    static func eventBody(
        event: String,
        properties: [String: Any],
        appVersion: String,
        language: String,
        installID: String
    ) -> [String: Any] {
        [
            "event": event,
            "properties": jsonSafeProperties(properties),
            "app_version": appVersion,
            "language": language,
            "install_id": installID
        ]
    }
    
    /// Bool is checked before Int so `true` does not bridge to `1`.
    static func jsonSafeProperties(_ properties: [String: Any]) -> [String: Any] {
        var jsonProperties: [String: Any] = [:]
        for (key, value) in properties {
            if let boolVal = value as? Bool {
                jsonProperties[key] = boolVal
            } else if let intVal = value as? Int {
                jsonProperties[key] = intVal
            } else if let doubleVal = value as? Double {
                jsonProperties[key] = doubleVal
            } else {
                jsonProperties[key] = "\(value)"
            }
        }
        return jsonProperties
    }
    
    private func incrementCounter(_ key: String) {
        let current = getCounter(key)
        UserDefaults.standard.set(current + 1, forKey: "analytics_counter_\(key)")
    }
    
    func getCounter(_ key: String) -> Int {
        return UserDefaults.standard.integer(forKey: "analytics_counter_\(key)")
    }
    
    private func getEvents() -> [[String: Any]] {
        guard let data = UserDefaults.standard.data(forKey: "analytics_events"),
              let events = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return events
    }
    
    private func saveEvents(_ events: [[String: Any]]) {
        guard let data = try? JSONSerialization.data(withJSONObject: events) else { return }
        UserDefaults.standard.set(data, forKey: "analytics_events")
    }
    
    private func getCurrentHour() -> Int {
        return Calendar.current.component(.hour, from: Date())
    }
    
    private func getCurrentDayOfWeek() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
    
    private func getInstallDate() -> String {
        if let installDate = UserDefaults.standard.object(forKey: "analytics_install_date") as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: installDate)
        } else {
            let now = Date()
            UserDefaults.standard.set(now, forKey: "analytics_install_date")
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: now)
        }
    }
    
    private func getDaysSinceInstall() -> Int {
        guard let installDate = UserDefaults.standard.object(forKey: "analytics_install_date") as? Date else {
            return 0
        }
        let days = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return days
    }
    
    // MARK: - Debug View Data
    
    func getRecentEvents(limit: Int = 20) -> [[String: Any]] {
        let events = getEvents()
        return Array(events.suffix(limit))
    }
}
