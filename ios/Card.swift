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

extension Card {
    /// The semantic title used anywhere a note is represented as a compact row
    /// or widget item. Full Markdown remains available in `simplifiedText` for
    /// the note detail and editor.
    var displayTitle: String { MarkdownSummary.title(in: simplifiedText) }
}

/// Markdown's compact projection. Kept with `Card` because the same source is
/// compiled by the app and widget targets.
enum MarkdownSummary {
    static func title(in markdown: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)

        if let heading = lines.lazy.compactMap({ levelOneHeading(in: $0) }).first {
            return plainText(heading)
        }

        // Existing notes have no explicit marker: their first non-empty line
        // remains the title, preserving Miranda's original content contract.
        let fallback = lines.first(where: isParagraphLine)
            ?? lines.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            ?? ""
        return plainText(fallback)
    }

    static func isParagraphLine(_ line: String) -> Bool {
        let value = line.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty,
              !value.hasPrefix("#"),
              !value.hasPrefix(">"),
              !value.hasPrefix("|")
        else { return false }
        return value.range(of: #"^(?:[-+*]|\d+[.)])\s+"#, options: .regularExpression) == nil
    }

    private static func levelOneHeading(in line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("# "), !trimmed.hasPrefix("## ") else { return nil }
        return String(trimmed.dropFirst(2))
    }

    static func plainText(_ markdown: String) -> String {
        var value = markdown.trimmingCharacters(in: .whitespacesAndNewlines)

        if let heading = value.range(of: #"^#{1,6}\s+"#, options: .regularExpression) {
            value.removeSubrange(heading)
        }

        // Remove block prefixes that can become the legacy fallback.
        while value.hasPrefix(">") {
            value.removeFirst()
            value = value.trimmingCharacters(in: .whitespaces)
        }
        if let match = value.range(of: #"^(?:[-+*]|\d+[.)])\s+"#, options: .regularExpression) {
            value.removeSubrange(match)
        }

        // Images are intentionally unsupported; retain their useful alt text.
        value = value.replacingOccurrences(
            of: #"!\[([^\]]*)\]\([^)]*\)"#,
            with: "$1",
            options: .regularExpression
        )
        value = value.replacingOccurrences(
            of: #"\[([^\]]+)\]\([^)]*\)"#,
            with: "$1",
            options: .regularExpression
        )
        value = value.replacingOccurrences(
            of: #"(\*\*|__|~~|`|\*|_)"#,
            with: "",
            options: .regularExpression
        )
        value = value.replacingOccurrences(
            of: #"\\([\\`*_{}\[\]()#+.!>\-])"#,
            with: "$1",
            options: .regularExpression
        )
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
