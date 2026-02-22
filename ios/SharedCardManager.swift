import Foundation

// Shared manager to store/load current card for both app and widget
class SharedCardManager {
    static let shared = SharedCardManager()
    
    // IMPORTANT: Replace this with your actual app group identifier
    private let appGroupID = "group.com.pabloserrano.onemust"
    
    // MARK: — Emoji Stripping
    // Strip emojis at the data layer so the widget never sees them
    private func stripEmoji(_ text: String) -> String {
        return text.filter { scalar in
            // Keep if not emoji
            // Emoji ranges: U+1F300–1F9FF (symbols, emoticons, transport)
            //               U+2600–26FF (misc symbols)
            //               U+2700–27BF (dingbats)
            //               U+FE00–FE0F (variation selectors)
            //               U+1F000–1F02F (Mahjong, Domino)
            //               U+1F0A0–1F0FF (playing cards)
            guard let first = scalar.unicodeScalars.first else { return true }
            let value = first.value
            
            // Exclude emoji ranges
            if (value >= 0x1F300 && value <= 0x1F9FF) { return false }
            if (value >= 0x2600 && value <= 0x26FF) { return false }
            if (value >= 0x2700 && value <= 0x27BF) { return false }
            if (value >= 0xFE00 && value <= 0xFE0F) { return false }
            if (value >= 0x1F000 && value <= 0x1F02F) { return false }
            if (value >= 0x1F0A0 && value <= 0x1F0FF) { return false }
            
            return true
        }.trimmingCharacters(in: .whitespaces)
    }
    
    private func stripCardEmoji(_ card: Card) -> Card {
        return Card(
            id: card.id,
            originalText: stripEmoji(card.originalText),
            simplifiedText: stripEmoji(card.simplifiedText),
            emoji: card.emoji,  // Keep emoji field for app use
            timestamp: card.timestamp
        )
    }
    
    // Lazy initialization to avoid iOS Simulator kCFPreferencesAnyUser error
    private lazy var sharedDefaults: UserDefaults? = {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("⚠️ Failed to initialize UserDefaults with App Group: \(appGroupID)")
            return nil
        }
        
        // Force synchronize to initialize the container properly
        defaults.synchronize()
        return defaults
    }()
    
    func saveCurrentCard(_ card: Card?) {
        guard let defaults = sharedDefaults else { 
            print("⚠️ SharedCardManager: No shared defaults available")
            return 
        }
        
        let encoder = JSONEncoder()
        
        if let card = card {
            let strippedCard = stripCardEmoji(card)
            if let data = try? encoder.encode(strippedCard) {
                defaults.set(data, forKey: "sharedCurrentCard")
                defaults.synchronize()
            }
        } else {
            defaults.removeObject(forKey: "sharedCurrentCard")
            defaults.synchronize()
        }
    }
    
    func loadCurrentCard() -> Card? {
        guard let defaults = sharedDefaults else { return nil }
        
        let decoder = JSONDecoder()
        
        if let data = defaults.data(forKey: "sharedCurrentCard"),
           let card = try? decoder.decode(Card.self, from: data) {
            return card
        }
        
        return nil
    }
    
    // Save multiple priority cards (up to 3)
    func savePriorityCards(_ cards: [Card]) {
        guard let defaults = sharedDefaults else { 
            print("⚠️ SharedCardManager: No shared defaults available")
            return 
        }
        
        let encoder = JSONEncoder()
        
        // Strip emojis from text before saving to shared container
        let strippedCards = cards.map { stripCardEmoji($0) }
        
        if let data = try? encoder.encode(strippedCards) {
            defaults.set(data, forKey: "sharedPriorityCards")
            defaults.synchronize()
        } else {
            defaults.removeObject(forKey: "sharedPriorityCards")
            defaults.synchronize()
        }
    }
    
    // Load all priority cards
    func loadPriorityCards() -> [Card] {
        guard let defaults = sharedDefaults else { return [] }
        
        let decoder = JSONDecoder()
        
        if let data = defaults.data(forKey: "sharedPriorityCards"),
           let cards = try? decoder.decode([Card].self, from: data) {
            return cards
        }
        
        return []
    }
    
    // Save all cards
    func saveAllCards(_ cards: [Card]) {
        guard let defaults = sharedDefaults else { 
            print("⚠️ SharedCardManager: No shared defaults available")
            return 
        }
        
        let encoder = JSONEncoder()
        
        // Strip emojis from text before saving to shared container
        let strippedCards = cards.map { stripCardEmoji($0) }
        
        if let data = try? encoder.encode(strippedCards) {
            defaults.set(data, forKey: "sharedAllCards")
            defaults.synchronize()
        }
    }
    
    // Load all cards
    func loadAllCards() -> [Card] {
        guard let defaults = sharedDefaults else { return [] }
        
        let decoder = JSONDecoder()
        
        if let data = defaults.data(forKey: "sharedAllCards"),
           let cards = try? decoder.decode([Card].self, from: data) {
            return cards
        }
        
        return []
    }
    
    // MARK: — Completed Cards (Archive)
    
    // Save a completed card to the archive
    func saveCompletedCard(_ card: Card) {
        var completedCards = loadCompletedCards()
        let strippedCard = stripCardEmoji(card)
        completedCards.append(strippedCard)
        
        guard let defaults = sharedDefaults else {
            print("⚠️ SharedCardManager: No shared defaults available")
            return
        }
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(completedCards) {
            defaults.set(data, forKey: "sharedCompletedCards")
            defaults.synchronize()
        }
    }
    
    // Load all completed cards
    func loadCompletedCards() -> [Card] {
        guard let defaults = sharedDefaults else { return [] }
        
        let decoder = JSONDecoder()
        
        if let data = defaults.data(forKey: "sharedCompletedCards"),
           let cards = try? decoder.decode([Card].self, from: data) {
            return cards
        }
        
        return []
    }
    
    // Clear completed cards (called after main app has synced completions)
    func clearCompletedCards() {
        guard let defaults = sharedDefaults else { return }
        defaults.removeObject(forKey: "sharedCompletedCards")
        defaults.synchronize()
    }
}
