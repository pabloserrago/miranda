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
                "Note something in \(.applicationName)"
            ],
            shortTitle: "Capture a note",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: ShowTopPriorityIntent(),
            phrases: [
                "What's my priority in \(.applicationName)",
                "What should I be doing in \(.applicationName)",
                "Show my top priority in \(.applicationName)"
            ],
            shortTitle: "Show top priority",
            systemImageName: "star.circle"
        )
        AppShortcut(
            intent: CompleteTopPriorityIntent(),
            phrases: [
                "I'm done in \(.applicationName)",
                "Mark done in \(.applicationName)",
                "Complete my priority in \(.applicationName)"
            ],
            shortTitle: "Mark done",
            systemImageName: "checkmark.circle"
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
// extension ShowTopPriorityIntent: <#ProductivityIntentDomain#> { }
// extension CompleteTopPriorityIntent: <#ProductivityIntentDomain#> { }
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

    @Parameter(title: "Note text")
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

        var allCards = loadCards(from: .standard)
        var priorityIds = loadPriorityIds(from: .standard)
        let excludedIds = loadExcludedIds(from: .standard)

        allCards.append(newCard)

        let activePriorityCount = priorityIds.filter { !excludedIds.contains($0) }.count
        if activePriorityCount < 3 {
            priorityIds.append(newCard.id)
        }

        saveCards(allCards, priorityIds: priorityIds, to: .standard)
        reloadWidget()

        return .result(value: String(localized: "intent.capture.result_format", defaultValue: "Captured: \(trimmed)", comment: "Siri intent result shown in Shortcuts"))
    }
}

// MARK: — Show Top Priority Intent

struct ShowTopPriorityIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Top Priority"
    static var description = IntentDescription("Read out your current top priority in Miranda.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let text = Self.topPriorityText(from: .standard)
        let response = text ?? String(
            localized: "intent.show_priority.empty",
            defaultValue: "You have no active priorities in Miranda.",
            comment: "Siri response when there are no active priorities"
        )
        return .result(value: response)
    }

    /// Returns the display text of the top active priority, or nil if none exist.
    static func topPriorityText(from defaults: UserDefaults) -> String? {
        let allCards = loadCards(from: defaults)
        let priorityIds = loadPriorityIds(from: defaults)
        let excludedIds = loadExcludedIds(from: defaults)
        let cardMap = Dictionary(uniqueKeysWithValues: allCards.map { ($0.id, $0) })
        return priorityIds
            .filter { !excludedIds.contains($0) }
            .compactMap { cardMap[$0] }
            .first?
            .simplifiedText
    }
}

// MARK: — Complete Top Priority Intent

struct CompleteTopPriorityIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Top Priority"
    static var description = IntentDescription("Mark your current top priority as done in Miranda.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let completedText = Self.completeTopPriority(in: .standard)
        reloadWidget()
        let response: String
        if let text = completedText {
            let format = String(
                localized: "intent.complete_priority.result_format",
                defaultValue: "Done: %@",
                comment: "Siri response after completing a priority — %@ is the completed note text"
            )
            response = String(format: format, text)
        } else {
            response = String(
                localized: "intent.complete_priority.empty",
                defaultValue: "No active priority to complete.",
                comment: "Siri response when there are no active priorities to complete"
            )
        }
        return .result(value: response)
    }

    /// Removes the current top priority from `cards` and `priorityCardIds`.
    /// Returns the completed card's display text, or nil if there was nothing to complete.
    @discardableResult
    static func completeTopPriority(in defaults: UserDefaults) -> String? {
        var allCards = loadCards(from: defaults)
        var priorityIds = loadPriorityIds(from: defaults)
        let excludedIds = loadExcludedIds(from: defaults)

        guard let completedId = priorityIds.first(where: { !excludedIds.contains($0) }) else {
            return nil
        }

        let completedText = allCards.first(where: { $0.id == completedId })?.simplifiedText

        allCards.removeAll { $0.id == completedId }
        priorityIds.removeAll { $0 == completedId }

        saveCards(allCards, priorityIds: priorityIds, to: defaults)
        return completedText
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
