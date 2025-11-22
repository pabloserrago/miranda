import Foundation

struct Card: Identifiable, Codable, Equatable {
    let id: UUID
    let originalText: String
    let simplifiedText: String
    let emoji: String?
    let timestamp: Date
    
    init(id: UUID = UUID(), originalText: String, simplifiedText: String, emoji: String?, timestamp: Date) {
        self.id = id
        self.originalText = originalText
        self.simplifiedText = simplifiedText
        self.emoji = emoji
        self.timestamp = timestamp
    }
}

