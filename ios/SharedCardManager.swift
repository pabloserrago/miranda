import Foundation

// Shared manager to store/load current card for both app and widget
class SharedCardManager {
    static let shared = SharedCardManager()
    
    // IMPORTANT: Replace this with your actual app group identifier
    private let appGroupID = "group.com.pabloserrano.onemust"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    func saveCurrentCard(_ card: Card?) {
        guard let defaults = sharedDefaults else { return }
        
        let encoder = JSONEncoder()
        
        if let card = card,
           let data = try? encoder.encode(card) {
            defaults.set(data, forKey: "sharedCurrentCard")
        } else {
            defaults.removeObject(forKey: "sharedCurrentCard")
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
}

