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
}
