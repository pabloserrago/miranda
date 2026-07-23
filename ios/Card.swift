import Foundation

struct Card: Identifiable, Codable, Equatable {
    let id: UUID
    let originalText: String
    let simplifiedText: String
    let emoji: String?
    let timestamp: Date
    
    init(id: UUID = UUID(), originalText: String, simplifiedText: String, emoji: String?, timestamp: Date) {
        self.id = id
        self.originalText = originalText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.simplifiedText = simplifiedText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.emoji = emoji
        self.timestamp = timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        originalText = try container.decode(String.self, forKey: .originalText)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        simplifiedText = try container.decode(String.self, forKey: .simplifiedText)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
}

