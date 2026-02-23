import Foundation

// Lightweight analytics for tracking app usage
class Analytics {
    static let shared = Analytics()
    
    private let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }()
    
    private let appLanguage: String = {
        Locale.current.language.languageCode?.identifier ?? "en"
    }()
    
    private init() {}
    
    // MARK: - Event Tracking
    
    func trackAppOpened() {
        logEvent("app_opened")
        incrementCounter("total_app_opens")
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
        
        // Send to Supabase (fire-and-forget)
        sendToSupabase(event: name, properties: properties)
        
        // Print to console for debugging
        print("📊 Analytics: \(name) - \(properties)")
    }
    
    private func sendToSupabase(event: String, properties: [String: Any]) {
        guard let url = URL(string: "\(Secrets.supabaseURL)/rest/v1/analytics") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Secrets.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        // Convert properties to JSON-safe types
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
        
        let body: [String: Any] = [
            "event": event,
            "properties": jsonProperties,
            "app_version": appVersion,
            "language": appLanguage
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }
    
    private func incrementCounter(_ key: String) {
        let current = getCounter(key)
        UserDefaults.standard.set(current + 1, forKey: "analytics_counter_\(key)")
    }
    
    private func getCounter(_ key: String) -> Int {
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
