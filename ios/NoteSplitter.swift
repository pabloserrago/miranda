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
}
