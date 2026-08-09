import Foundation

/// Splits note text into multiple note texts when the "Split by Hyphens"
/// setting is enabled. Each line starting with "-" begins a new item;
/// other lines attach to the current item (or the leading block).
enum NoteSplitter {
    static func split(_ text: String) -> [String] {
        var items: [String] = []
        var current: [String] = []

        func flush() {
            let item = current.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !item.isEmpty { items.append(item) }
            current = []
        }

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("-") {
                flush()
                current.append(String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))
            } else {
                current.append(line)
            }
        }
        flush()
        return items
    }

    /// Live-editor rule: when the text ends with a newline and the line just
    /// completed starts with "-", everything typed so far is committed as
    /// note segments and the editor is cleared. Otherwise nothing happens.
    static func commitAfterNewline(_ activeText: String) -> (committed: [String], remaining: String) {
        guard activeText.hasSuffix("\n") else { return ([], activeText) }
        let completedLines = activeText.dropLast().components(separatedBy: .newlines)
        guard let lastLine = completedLines.last,
              lastLine.trimmingCharacters(in: .whitespaces).hasPrefix("-") else {
            return ([], activeText)
        }
        return (split(activeText), "")
    }

    /// Rebuilds raw text from committed segments plus the in-progress text so
    /// that `split(canonicalText(...)) == segments + split(activeText)`.
    static func canonicalText(segments: [String], activeText: String) -> String {
        guard !segments.isEmpty else { return activeText }
        return (segments + split(activeText))
            .map { "- " + $0 }
            .joined(separator: "\n")
    }

    /// Outcome of saving an edited note that may split into several notes.
    struct EditResult {
        /// The edited note, keeping its original identity (id, emoji, timestamp).
        let updatedOriginal: Card
        /// Additional notes produced by the split, in order, as brand-new notes.
        let newCards: [Card]
    }

    /// Applies an edit that splits into `splitTexts`. The first text updates the
    /// original in place so it keeps its priority slot and metadata; the rest
    /// become new notes (no emoji, fresh timestamps). Returns nil when there is
    /// nothing to save.
    static func applyEdit(to original: Card, splitTexts: [String], now: Date = Date()) -> EditResult? {
        guard let first = splitTexts.first else { return nil }
        let updated = Card(
            id: original.id,
            originalText: first,
            simplifiedText: first,
            emoji: original.emoji,
            timestamp: original.timestamp
        )
        let rest = splitTexts.dropFirst().map {
            Card(originalText: $0, simplifiedText: $0, emoji: nil, timestamp: now)
        }
        return EditResult(updatedOriginal: updated, newCards: Array(rest))
    }
}
