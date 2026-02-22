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
        
        let defaults = UserDefaults(suiteName: "group.com.pabloserrano.onemust")
        
        // 1. Archive the completed card as a note
        let allCards = SharedCardManager.shared.loadAllCards()
        if let completedCard = allCards.first(where: { $0.id == cardIdUUID }) {
            SharedCardManager.shared.saveCompletedCard(completedCard)
        }
        
        // 2. Remove from active lists immediately (ensures card disappears)
        let updatedAllCards = allCards.filter { $0.id != cardIdUUID }
        let priorityCards = SharedCardManager.shared.loadPriorityCards().filter { $0.id != cardIdUUID }
        
        SharedCardManager.shared.saveAllCards(updatedAllCards)
        SharedCardManager.shared.savePriorityCards(priorityCards)
        SharedCardManager.shared.saveCurrentCard(priorityCards.first)
        
        // 3. Set the completion flag for dopamine beat (Provider will read this)
        defaults?.set(cardId, forKey: "completingCardID")
        defaults?.synchronize()
        
        // 4. Trigger timeline reload
        WidgetCenter.shared.reloadTimelines(ofKind: "OneMustWidget")
        
        return .result()
    }
}
