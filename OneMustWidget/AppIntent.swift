//
//  AppIntent.swift
//  OneMustWidget
//
//  Created by Pablo Serrano on 10/28/25.
//

import WidgetKit
import AppIntents

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
        
        // Mark which card is being completed (for dopamine beat timeline)
        UserDefaults(suiteName: "group.com.ahad.oneMust")?.set(cardId, forKey: "completingCardID")
        
        // Remove from data layer
        let allCards = SharedCardManager.shared.loadAllCards().filter { $0.id != cardIdUUID }
        let priorityCards = SharedCardManager.shared.loadPriorityCards().filter { $0.id != cardIdUUID }
        
        SharedCardManager.shared.saveAllCards(allCards)
        SharedCardManager.shared.savePriorityCards(priorityCards)
        SharedCardManager.shared.saveCurrentCard(priorityCards.first)
        
        // Also update main app UserDefaults
        let encoder = JSONEncoder()
        if let cardsData = try? encoder.encode(allCards) {
            UserDefaults.standard.set(cardsData, forKey: "cards")
        }
        
        let priorityStrings = priorityCards.map { $0.id.uuidString }
        UserDefaults.standard.set(priorityStrings, forKey: "priorityCardIds")
        
        // Trigger timeline reload — Provider will build the two-entry arc
        WidgetCenter.shared.reloadTimelines(ofKind: "OneMustWidget")
        
        return .result()
    }
}
