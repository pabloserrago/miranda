import AppIntents
import WidgetKit
import Foundation

// MARK: — App Shortcuts Provider

struct MirandaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureNoteIntent(),
            phrases: [
                "Capture a note in \(.applicationName)",
                "Add a note to \(.applicationName)",
                "Note something in \(.applicationName)",
                "Capture this in \(.applicationName)",
                "Add this to \(.applicationName)",
                "Add to \(.applicationName)"
            ],
            shortTitle: "Capture a note",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: RemoveAllPrioritiesIntent(),
            phrases: [
                "Remove all priorities in \(.applicationName)"
            ],
            shortTitle: "Remove all priorities",
            systemImageName: "lightbulb.slash"
        )
        AppShortcut(
            intent: CaptureAndPrioritizeIntent(),
            phrases: [
                "Add priority to \(.applicationName)",
                "Set my priority in \(.applicationName)"
            ],
            shortTitle: "Set priority",
            systemImageName: "arrow.up.circle"
        )
    }
}

// MARK: — Productivity Domain (iOS 27+)
// Registers Miranda with Siri AI's productivity intent domain so
// Gemini-powered Siri can discover and chain Miranda actions.
//
// The exact protocol name must be confirmed from the Xcode 27 beta documentation
// at developer.apple.com/wwdc26 (App Intent Domains release notes).
// Uncomment all four conformances once the protocol is available and rebuild with Xcode 27:
//
// @available(iOS 27, *)
// extension CaptureNoteIntent: <#ProductivityIntentDomain#> { }
// extension RemoveAllPrioritiesIntent: <#ProductivityIntentDomain#> { }
// extension CaptureAndPrioritizeIntent: <#ProductivityIntentDomain#> { }

// MARK: — Shared State Helpers

private func loadCards(from defaults: UserDefaults) -> [Card] {
    guard let data = defaults.data(forKey: "cards"),
          let cards = try? JSONDecoder().decode([Card].self, from: data) else { return [] }
    return cards
}

private func loadPriorityIds(from defaults: UserDefaults) -> [UUID] {
    (defaults.array(forKey: "priorityCardIds") as? [String] ?? []).compactMap { UUID(uuidString: $0) }
}

private func loadExcludedIds(from defaults: UserDefaults) -> [UUID] {
    (defaults.array(forKey: "excludedFromPriorityIds") as? [String] ?? []).compactMap { UUID(uuidString: $0) }
}

private func saveCards(_ cards: [Card], priorityIds: [UUID], to defaults: UserDefaults) {
    if let data = try? JSONEncoder().encode(cards) {
        defaults.set(data, forKey: "cards")
    }
    defaults.set(priorityIds.map { $0.uuidString }, forKey: "priorityCardIds")
}

/// Reads the latest persisted state and pushes it to the widget extension.
private func reloadWidget() {
    let allCards = loadCards(from: .standard)
    let priorityIds = loadPriorityIds(from: .standard)
    let excludedIds = loadExcludedIds(from: .standard)
    let widgetCards = Array(
        allCards
            .filter { priorityIds.contains($0.id) && !excludedIds.contains($0.id) }
            .prefix(3)
    )
    SharedCardManager.shared.saveAllCards(allCards)
    SharedCardManager.shared.savePriorityCards(widgetCards)
    SharedCardManager.shared.saveCurrentCard(widgetCards.first)
    WidgetCenter.shared.reloadAllTimelines()
}

// MARK: — Capture Note Intent

struct CaptureNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture a Note"
    static var description = IntentDescription("Add a new priority note to Miranda.")

    @Parameter(
        title: "Note text",
        requestValueDialog: "What would you like to add to Miranda?"
    )
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw $text.needsValueError("What would you like to capture?")
        }

        let newCard = Card(
            originalText: trimmed,
            simplifiedText: trimmed,
            emoji: nil,
            timestamp: Date()
        )
        Self.capture(newCard, in: .standard)
        reloadWidget()
        Analytics.shared.trackIntentRun("capture_note")

        return .result(value: String(localized: "intent.capture.result_format", defaultValue: "Captured: \(trimmed)", comment: "Siri intent result shown in Shortcuts"))
    }

    /// Persists a dictated note and fills an available priority slot, matching
    /// the in-app capture behavior while keeping the transformation testable.
    static func capture(_ card: Card, in defaults: UserDefaults) {
        var allCards = loadCards(from: defaults)
        var priorityIds = loadPriorityIds(from: defaults)
        let excludedIds = loadExcludedIds(from: defaults)

        allCards.append(card)

        let activePriorityCount = priorityIds.filter { !excludedIds.contains($0) }.count
        if activePriorityCount < 3 {
            priorityIds.append(card.id)
        }

        saveCards(allCards, priorityIds: priorityIds, to: defaults)
    }
}

// MARK: — Remove All Priorities Intent

struct RemoveAllPrioritiesIntent: AppIntent {
    static var title: LocalizedStringResource = "Remove All Priorities"
    static var description = IntentDescription("Turn off every active priority in Miranda without deleting the notes.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let removedCount = Self.removeAllPriorities(in: .standard)
        reloadWidget()
        Analytics.shared.trackIntentRun("remove_all_priorities")
        let response = removedCount == 0
            ? "No active priorities to remove."
            : "Removed all priorities. Your notes are still in Miranda."
        return .result(value: response)
    }

    /// Excludes every note from the active priority list without deleting it.
    @discardableResult
    static func removeAllPriorities(in defaults: UserDefaults) -> Int {
        let allCards = loadCards(from: defaults)
        let excludedIds = Set(loadExcludedIds(from: defaults))
        let activeIds = allCards.map(\.id).filter { !excludedIds.contains($0) }

        defaults.set(
            Array(excludedIds.union(activeIds)).map { $0.uuidString },
            forKey: "excludedFromPriorityIds"
        )
        return activeIds.count
    }
}

// MARK: — Capture and Prioritize Intent

struct CaptureAndPrioritizeIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Priority"
    static var description = IntentDescription("Capture a note and make it your top priority in Miranda, replacing the oldest if you already have 3.")

    @Parameter(title: "Priority text")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw $text.needsValueError("What should your priority be?")
        }

        let newCard = Card(
            originalText: trimmed,
            simplifiedText: trimmed,
            emoji: nil,
            timestamp: Date()
        )
        Self.insertAsPriority(newCard, in: .standard)
        reloadWidget()
        Analytics.shared.trackIntentRun("capture_and_prioritize")

        let resultFormat = String(
            localized: "intent.set_priority.result_format",
            defaultValue: "Priority set: %@",
            comment: "Siri response after setting a new top priority — %@ is the note text"
        )
        return .result(value: String(format: resultFormat, trimmed))
    }

    /// Inserts `card` as the top priority. If there are already 3 active priorities,
    /// the oldest one (first in the ordered list) is evicted from priorities but kept in cards.
    static func insertAsPriority(_ card: Card, in defaults: UserDefaults) {
        var allCards = loadCards(from: defaults)
        var priorityIds = loadPriorityIds(from: defaults)
        let excludedIds = loadExcludedIds(from: defaults)

        allCards.append(card)

        let activePriorityIds = priorityIds.filter { !excludedIds.contains($0) }
        if activePriorityIds.count >= 3, let oldestId = activePriorityIds.first {
            priorityIds.removeAll { $0 == oldestId }
        }

        priorityIds.insert(card.id, at: 0)
        saveCards(allCards, priorityIds: priorityIds, to: defaults)
    }
}
