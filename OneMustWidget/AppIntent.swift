//
//  AppIntent.swift
//  OneMustWidget
//
//  Created by Pablo Serrano on 10/28/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

// Intent to complete a priority card from widget
struct CompleteCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Card"
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Card ID")
    var cardId: String
    
    init(cardId: String) {
        self.cardId = cardId
    }
    
    init() {
        self.cardId = ""
    }
    
    func perform() async throws -> some IntentResult {
        guard let cardIdUUID = UUID(uuidString: cardId) else {
            return .result()
        }
        
        // Trigger dual-entry timeline (dopamine beat + promotion)
        Provider.pushCompletionTimeline(completedID: cardIdUUID)
        
        // Also update main app UserDefaults
        let allCards = SharedCardManager.shared.loadAllCards().filter { $0.id != cardIdUUID }
        let priorityCards = SharedCardManager.shared.loadPriorityCards().filter { $0.id != cardIdUUID }
        
        SharedCardManager.shared.saveAllCards(allCards)
        SharedCardManager.shared.saveCurrentCard(priorityCards.first)
        
        let encoder = JSONEncoder()
        if let cardsData = try? encoder.encode(allCards) {
            UserDefaults.standard.set(cardsData, forKey: "cards")
        }
        
        let priorityStrings = priorityCards.map { $0.id.uuidString }
        UserDefaults.standard.set(priorityStrings, forKey: "priorityCardIds")
        
        return .result()
    }
}
