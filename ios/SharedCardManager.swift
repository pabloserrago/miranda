import Foundation

// Shared manager to store/load current card for both app and widget
class SharedCardManager {
    static let shared = SharedCardManager()
    
    // IMPORTANT: Replace this with your actual app group identifier
    private let appGroupID = "group.com.pabloserrano.onemust"
    
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
        
        if let card = card,
           let data = try? encoder.encode(card) {
            defaults.set(data, forKey: "sharedCurrentCard")
            defaults.synchronize()
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
        
        if let data = try? encoder.encode(cards) {
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
        
        if let data = try? encoder.encode(cards) {
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
}
