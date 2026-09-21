import SwiftUI

struct MarkdownDocument {
    enum Block: Equatable {
        case heading(level: Int, text: String)
        case paragraph(String)
        case quote(String)
        case unorderedList([ListItem])
        case orderedList([ListItem])
        case table(headers: [String], rows: [[String]], alignments: [Alignment])
    }

    struct ListItem: Equatable, Identifiable {
        let id = UUID()
        let text: String
        let depth: Int

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.text == rhs.text && lhs.depth == rhs.depth
        }
    }

    let blocks: [Block]

    init(_ source: String) {
        blocks = Self.parse(source)
    }

    private static func parse(_ source: String) -> [Block] {
        let rawLines = source.components(separatedBy: .newlines)
        var lines = rawLines
        let firstContentIndex = lines.firstIndex(where: MarkdownSummary.isParagraphLine)

        // Backward compatibility: before Markdown, Miranda's first content line
        // was always the title. Promote it only when the document has no H1.
        let hasH1 = lines.contains { line in
            let value = line.trimmingCharacters(in: .whitespaces)
            return value.hasPrefix("# ") && !value.hasPrefix("## ")
        }
        if !hasH1, let index = firstContentIndex {
            lines[index] = "# " + lines[index]
        }

        var result: [Block] = []
        var index = 0
        while index < lines.count {
            let raw = lines[index]
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { index += 1; continue }

            if let heading = heading(from: trimmed) {
                result.append(.heading(level: heading.level, text: heading.text))
                index += 1
                continue
            }

            if index + 1 < lines.count,
               isTableDivider(lines[index + 1]),
               splitTableRow(raw).count > 0 {
                let headers = splitTableRow(raw)
                let alignments = tableAlignments(lines[index + 1], count: headers.count)
                index += 2
                var rows: [[String]] = []
                while index < lines.count {
                    let row = splitTableRow(lines[index])
                    guard !row.isEmpty else { break }
                    rows.append(normalized(row, count: headers.count))
                    index += 1
                }
                result.append(.table(headers: headers, rows: rows, alignments: alignments))
                continue
            }

            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while index < lines.count {
                    let value = lines[index].trimmingCharacters(in: .whitespaces)
                    guard value.hasPrefix(">") else { break }
                    quoteLines.append(String(value.dropFirst()).trimmingCharacters(in: .whitespaces))
                    index += 1
                }
                result.append(.quote(quoteLines.joined(separator: "\n")))
                continue
            }

            if let item = listItem(from: raw) {
                var items = [item.item]
                let ordered = item.ordered
                index += 1
                while index < lines.count,
                      let next = listItem(from: lines[index]), next.ordered == ordered {
                    items.append(next.item)
                    index += 1
                }
                result.append(ordered ? .orderedList(items) : .unorderedList(items))
                continue
            }

            var paragraph = [trimmed]
            index += 1
            while index < lines.count {
                let next = lines[index].trimmingCharacters(in: .whitespaces)
                guard !next.isEmpty,
                      heading(from: next) == nil,
                      !next.hasPrefix(">"),
                      listItem(from: lines[index]) == nil,
                      !(index + 1 < lines.count && isTableDivider(lines[index + 1]))
                else { break }
                paragraph.append(next)
                index += 1
            }
            result.append(.paragraph(paragraph.joined(separator: " ")))
        }
        return result
    }

    private static func heading(from line: String) -> (level: Int, text: String)? {
        let hashes = line.prefix { $0 == "#" }.count
        guard (1...6).contains(hashes), line.dropFirst(hashes).first == " " else { return nil }
        return (hashes, String(line.dropFirst(hashes + 1)))
    }

    private static func listItem(from line: String) -> (ordered: Bool, item: ListItem)? {
        let spaces = line.prefix { $0 == " " || $0 == "\t" }.count
        let depth = min(spaces >= 2 ? 1 : 0, 1)
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if let range = trimmed.range(of: #"^[-+*]\s+"#, options: .regularExpression) {
            return (false, ListItem(text: String(trimmed[range.upperBound...]), depth: depth))
        }
        if let range = trimmed.range(of: #"^\d+[.)]\s+"#, options: .regularExpression) {
            return (true, ListItem(text: String(trimmed[range.upperBound...]), depth: depth))
        }
        return nil
    }

    private static func splitTableRow(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("|") else { return [] }
        return trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func isTableDivider(_ line: String) -> Bool {
        let cells = splitTableRow(line)
        return !cells.isEmpty && cells.allSatisfy {
            $0.range(of: #"^:?-{3,}:?$"#, options: .regularExpression) != nil
        }
    }

    private static func tableAlignments(_ line: String, count: Int) -> [Alignment] {
        normalized(splitTableRow(line), count: count).map { cell in
            if cell.hasPrefix(":"), cell.hasSuffix(":") { return .center }
            if cell.hasSuffix(":") { return .trailing }
            return .leading
        }
    }

    private static func normalized(_ cells: [String], count: Int) -> [String] {
        Array((cells + Array(repeating: "", count: max(0, count - cells.count))).prefix(count))
    }
}

private struct MarkdownInlineText: View {
    let source: String
    let font: Font
    let color: Color

    var body: some View {
        Text(attributed)
            .font(font)
            .foregroundStyle(color)
    }

    private var attributed: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        return (try? AttributedString(markdown: source, options: options))
            ?? AttributedString(MarkdownSummary.plainText(source))
    }
}

struct MarkdownDocumentView: View {
    let source: String

    private var document: MarkdownDocument { MarkdownDocument(source) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(document.blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownDocument.Block) -> some View {
        switch block {
        case let .heading(level, text):
            MarkdownInlineText(
                source: text,
                font: level == 1 ? AppFont.title : (level <= 3 ? AppFont.headline : AppFont.subhead),
                color: Material.Text.primary
            )
            .accessibilityAddTraits(.isHeader)

        case let .paragraph(text):
            MarkdownInlineText(source: text, font: AppFont.body, color: Material.Text.secondary)

        case let .quote(text):
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Material.Decoration.tertiary)
                    .frame(width: 3)
                MarkdownInlineText(source: text, font: AppFont.body, color: Material.Text.secondary)
                    .italic()
            }
            .padding(.vertical, 4)

        case let .unorderedList(items):
            list(items: items, ordered: false)

        case let .orderedList(items):
            list(items: items, ordered: true)

        case let .table(headers, rows, alignments):
            table(headers: headers, rows: rows, alignments: alignments)
        }
    }

    private func list(items: [MarkdownDocument.ListItem], ordered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 9) {
                    Text(ordered ? "\(index + 1)." : "•")
                        .font(AppFont.body)
                        .foregroundStyle(Material.Text.secondary)
                    MarkdownInlineText(source: item.text, font: AppFont.body, color: Material.Text.secondary)
                }
                .padding(.leading, CGFloat(item.depth) * 22)
            }
        }
    }

    private func table(headers: [String], rows: [[String]], alignments: [Alignment]) -> some View {
        ScrollView(.horizontal) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                tableRow(headers, alignments: alignments, header: true)
                Divider()
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    tableRow(row, alignments: alignments, header: false)
                    Divider()
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: Material.Shape.control)
                    .stroke(Material.Decoration.tertiary, lineWidth: 1)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func tableRow(_ cells: [String], alignments: [Alignment], header: Bool) -> some View {
        GridRow {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                MarkdownInlineText(
                    source: cell,
                    font: header ? AppFont.headline : AppFont.body,
                    color: header ? Material.Text.primary : Material.Text.secondary
                )
                .frame(minWidth: 110, maxWidth: 220, alignment: alignments[index])
                .padding(10)
                if index < cells.count - 1 { Divider() }
            }
        }
    }
}
