import SwiftUI

/// A saved note laid out for reading: the first line is the title and the lines
/// under it are body paragraphs. Blank lines are dropped because the preview
/// supplies its own paragraph spacing, so a note typed with gaps and one typed
/// without read the same.
struct NotePreviewContent: Equatable {
    let title: String
    let paragraphs: [String]

    init(text: String) {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        title = lines.first ?? ""
        paragraphs = Array(lines.dropFirst())
    }
}

extension NotePreviewContent {
    /// One line of a note with its URLs colored, underlined and openable. Only
    /// the link runs carry attributes so the caller's font and color still set
    /// the face — the same builder serves the title and the body.
    ///
    /// The editor styles links differently on purpose: there they are underlined
    /// but left in the body color, because a tap has to place the caret rather
    /// than leave the app.
    static func attributed(_ line: String) -> AttributedString {
        let ns = line as NSString
        var result = AttributedString()
        var cursor = 0

        // Sliced on UTF-16 offsets, which is what the detector reports; going
        // through String.Index would misalign on any non-BMP character.
        for match in NoteTextStyler.linkMatches(in: line) {
            if match.range.location > cursor {
                let gap = NSRange(location: cursor, length: match.range.location - cursor)
                result += AttributedString(ns.substring(with: gap))
            }

            var link = AttributedString(ns.substring(with: match.range))
            link.foregroundColor = Material.Text.accent
            link.underlineStyle = .single
            link.link = match.url
            result += link

            cursor = match.range.upperBound
        }

        if cursor < ns.length {
            result += AttributedString(ns.substring(from: cursor))
        }
        return result
    }
}

/// The note as the design shows it: a bold title, supporting paragraphs beneath
/// it, all centered.
struct NotePreviewText: View {
    let text: String

    var body: some View {
        let content = NotePreviewContent(text: text)

        VStack(spacing: 20) {
            if !content.title.isEmpty {
                Text(NotePreviewContent.attributed(content.title))
                    .font(AppFont.title)
                    .foregroundColor(Material.Text.primary)
                    .accessibilityIdentifier("note-preview-title")
            }

            if !content.paragraphs.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(content.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                        Text(NotePreviewContent.attributed(paragraph))
                            .font(AppFont.body)
                            .foregroundColor(Material.Text.secondary)
                    }
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Note Detail

/// A saved note, read back. Reached by tapping a note and also straight after
/// saving one, so the same screen confirms what was captured and offers the two
/// decisions worth making about it.
struct NoteDetailView: View {
    let card: Card
    @Binding var cards: [Card]
    @Binding var excludedFromPriorityIds: [UUID]
    let autoPriorityCardIds: Set<UUID>
    let onSave: () -> Void
    let onComplete: (Card) -> Void
    let onCompletePriority: (Card) -> Void
    let onClose: () -> Void
    let onNewNote: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isEditing = false
    @State private var editText = ""
    @AppStorage("hyphenSplitEnabled") private var hyphenSplitEnabled: Bool = false

    /// Editing rewrites the stored note, so the text is read back from `cards`
    /// rather than from the value this view was handed.
    private var live: Card {
        cards.first { $0.id == card.id } ?? card
    }

    private var isPriority: Bool {
        autoPriorityCardIds.contains(card.id)
    }

    var body: some View {
        Group {
            if isEditing {
                NoteEditor(
                    text: $editText,
                    mode: .edit,
                    onCancel: {
                        isEditing = false
                        editText = ""
                    },
                    onSave: saveEdit
                )
            } else {
                readingView
            }
        }
        .onAppear { Analytics.shared.trackCardViewed() }
    }

    private var readingView: some View {
        VStack(spacing: 0) {
            NoteChromeRow {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.editorIcon)
                .accessibilityLabel("Close")
                .accessibilityIdentifier("close-note-button")

                Spacer(minLength: 0)

                Button(action: onNewNote) {
                    Image(systemName: "plus.square.on.square")
                }
                .buttonStyle(.editorIcon)
                .accessibilityLabel("New note")
                .accessibilityIdentifier("new-note-from-preview-button")

                Button {
                    editText = live.simplifiedText
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.editorIcon)
                .accessibilityLabel("Edit note")
                .accessibilityIdentifier("edit-note-button")
            }

            // Short notes centre themselves in the space they are given; long
            // ones scroll from the top.
            ViewThatFits(in: .vertical) {
                noteBody
                ScrollView { noteBody }
            }
            .frame(maxHeight: .infinity)

            bottomActions
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Material.Surface.tertiary)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var noteBody: some View {
        NotePreviewText(text: live.simplifiedText)
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
    }

    // MARK: - Actions

    private var bottomActions: some View {
        Group {
            // Two capsules side by side stop fitting well before AX5, so the
            // largest sizes get the stacked arrangement instead of clipped labels.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    togglePriorityButton
                    doneButton
                }
            } else {
                HStack(spacing: 12) {
                    togglePriorityButton
                    doneButton
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Material.Surface.tertiary)
    }

    private var togglePriorityButton: some View {
        Button {
            if isPriority {
                if !excludedFromPriorityIds.contains(card.id) {
                    excludedFromPriorityIds.append(card.id)
                }
            } else {
                excludedFromPriorityIds.removeAll { $0 == card.id }
            }
            onSave()
            onClose()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isPriority ? "lightbulb.slash.fill" : "lightbulb.fill")
                    .fontWeight(.heavy)
                Text(isPriority ? "Turn Off" : "Turn On")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.filled)
        .accessibilityIdentifier("toggle-priority-button")
    }

    /// "Done" rather than "Mark as Done": the longer label wrapped onto two
    /// lines inside the capsule once the two actions shared a row.
    private var doneButton: some View {
        Button {
            onClose()
            if isPriority { onCompletePriority(card) }
            else { onComplete(card) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark").fontWeight(.heavy)
                Text("Done")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primaryGlass)
        .accessibilityIdentifier("done-button")
    }

    /// The editor hands back a single string with any hyphen segments already
    /// folded in, so this only has to decide how to split it into notes.
    private func saveEdit() {
        let texts = hyphenSplitEnabled
            ? NoteSplitter.split(editText)
            : [editText.trimmingCharacters(in: .whitespacesAndNewlines)].filter { !$0.isEmpty }
        guard let result = NoteSplitter.applyEdit(to: card, splitTexts: texts) else { return }

        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx] = result.updatedOriginal
        }
        for newCard in result.newCards {
            cards.append(newCard)
            let currentPriorityCount = cards.filter { !excludedFromPriorityIds.contains($0.id) }.count
            if currentPriorityCount > 3 { excludedFromPriorityIds.append(newCard.id) }
            Analytics.shared.trackCardCreated(hasEmoji: false)
        }
        onSave()
        isEditing = false
    }
}
