import SwiftUI
import EventKit

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

    /// The complete note is kept in one attributed string so selection can
    /// continue from the title through any number of paragraphs. Individual
    /// runs retain their visual role and links remain independently openable.
    var selectableText: AttributedString {
        func styled(_ line: String, font: Font, color: Color) -> AttributedString {
            var value = Self.attributed(line)
            value.font = font
            value.foregroundColor = color

            // Applying the base color styles every run, including links, so
            // restore their stronger interactive treatment afterwards.
            for run in value.runs where run.link != nil {
                value[run.range].foregroundColor = Material.Text.accent
            }
            return value
        }

        var result = styled(title, font: AppFont.title, color: Material.Text.primary)

        for paragraph in paragraphs {
            var separator = AttributedString("\n\n")
            separator.font = AppFont.body
            result += separator

            result += styled(paragraph, font: AppFont.body, color: Material.Text.secondary)
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

        Text(content.selectableText)
            .textSelection(.enabled)
            .accessibilityIdentifier("note-preview-title")
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isEditing = false
    @State private var editText = ""
    @State private var calendarEventRequest: CalendarEventEditRequest?
    @State private var showCalendarAccessError = false
    @State private var isDateVisible = false
    @State private var isTurningPriorityOn = false
    @State private var priorityRingProgress = 0.0
    @State private var priorityActivationTask: Task<Void, Never>?
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
        .onDisappear {
            priorityActivationTask?.cancel()
            priorityActivationTask = nil
        }
        .interactiveDismissDisabled(isEditing)
    }

    private var readingView: some View {
        VStack(spacing: 0) {
            NoteChromeRow {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .scaleEffect(1.1)
                }
                .buttonStyle(.editorIcon)
                .accessibilityLabel("Close")
                .accessibilityIdentifier("close-note-button")

                Spacer(minLength: 0)

                noteActionGroup
            }

            // Short notes centre themselves in the space they are given; long
            // ones scroll from the top.
            ViewThatFits(in: .vertical) {
                noteBody
                ScrollView { noteBody }
            }
            .frame(maxHeight: .infinity)
            .overlay(alignment: .top) {
                Text(live.timestamp.formatted(date: .long, time: .shortened))
                    .font(AppFont.caption)
                    .foregroundStyle(Material.Text.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)
                    .opacity(isDateVisible ? 1 : 0)
                    .accessibilityHidden(!isDateVisible)
                    .accessibilityIdentifier("note-date-caption")
            }

            bottomActions
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Material.Surface.tertiary)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let isDownwardSwipe = value.translation.height > abs(value.translation.width)
                    if isDownwardSwipe, value.translation.height >= 80 {
                        onClose()
                    } else if isDownwardSwipe {
                        isDateVisible = true
                    }
                }
        )
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $calendarEventRequest) { request in
            CalendarEventComposer(request: request) {
                calendarEventRequest = nil
            }
        }
        .alert("Calendar access needed", isPresented: $showCalendarAccessError) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Allow Miranda to add events to your calendar in Settings.")
        }
    }

    private var noteBody: some View {
        NotePreviewText(text: live.simplifiedText)
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
    }

    // MARK: - Actions

    @ViewBuilder
    private var noteActionGroup: some View {
        let actions = HStack(spacing: 2) {
            Button(action: onNewNote) {
                Image(systemName: "plus")
                    .scaleEffect(1.1)
                    .frame(width: Material.Shape.chipSmall, height: Material.Shape.chipSmall)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("New note")
            .accessibilityIdentifier("new-note-from-preview-button")

            Button(action: addToCalendar) {
                Image(systemName: "calendar.badge.plus")
                    .scaleEffect(1.1)
                    .frame(width: Material.Shape.chipSmall, height: Material.Shape.chipSmall)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Add to Calendar")
            .accessibilityIdentifier("add-note-to-calendar-button")

            Menu {
                Button {
                    editText = live.simplifiedText
                    isEditing = true
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                            .scaleEffect(1.1)
                        Text("Edit note")
                    }
                }
                .accessibilityIdentifier("edit-note-button")

                Button(role: .destructive) {
                    deleteNote()
                } label: {
                    Label("Delete note", systemImage: "trash")
                        .foregroundStyle(Material.Status.error)
                }
                .accessibilityIdentifier("delete-note-button")
            } label: {
                Image(systemName: "ellipsis")
                    .scaleEffect(1.1)
                    .frame(width: Material.Shape.chipSmall, height: Material.Shape.chipSmall)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More note actions")
            .accessibilityIdentifier("note-actions-menu-button")
        }
        .font(AppFont.body)
        .fontWeight(.medium)
        .foregroundStyle(Material.Text.primary)
        .buttonStyle(.plain)
        .clipShape(Capsule())

        if #available(iOS 26.0, *) {
            actions.glassEffect(.regular, in: Capsule())
        } else {
            actions
                .background(Material.Control.fillPrimary)
                .shadow(color: Material.Elevation.shadow.opacity(0.12), radius: 6, x: 0, y: 2)
        }
    }

    private func deleteNote() {
        cards.removeAll { $0.id == card.id }
        excludedFromPriorityIds.removeAll { $0 == card.id }
        onSave()
        onClose()
    }

    private func addToCalendar() {
        let eventStore = EKEventStore()
        Task { @MainActor in
            do {
                guard try await eventStore.requestWriteOnlyAccessToEvents() else {
                    showCalendarAccessError = true
                    return
                }
                calendarEventRequest = CalendarEventEditRequest(
                    eventStore: eventStore,
                    draft: CalendarEventDraft(noteText: live.simplifiedText)
                )
            } catch {
                showCalendarAccessError = true
            }
        }
    }

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
                turnPriorityOff()
            } else {
                beginTurningPriorityOn()
            }
        } label: {
            HStack(spacing: 8) {
                priorityIcon
                Text("Priority")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.priorityGlass(isOn: isPriority || isTurningPriorityOn))
        .disabled(isTurningPriorityOn)
        .accessibilityValue(isTurningPriorityOn ? "Turning on" : (isPriority ? "On" : "Off"))
        .accessibilityIdentifier("toggle-priority-button")
    }

    private var priorityIcon: some View {
        ZStack {
            if isTurningPriorityOn {
                Circle()
                    .stroke(Material.Text.primary.opacity(0.2), lineWidth: 2.5)
                    .frame(width: 28, height: 28)

                Circle()
                    .trim(from: 0, to: priorityRingProgress)
                    .stroke(Material.Text.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))
                    .onAppear {
                        withAnimation(Motion.gated(.linear(duration: 1), reduce: reduceMotion)) {
                            priorityRingProgress = 1
                        }
                    }
            }

            Image(systemName: isPriority ? "lightbulb.fill" : "lightbulb.slash.fill")
                .fontWeight(.heavy)
                .scaleEffect(isTurningPriorityOn ? 0.8 : 1)
                .animation(
                    Motion.gated(.easeInOut(duration: 0.2), reduce: reduceMotion),
                    value: isTurningPriorityOn
                )
        }
        .frame(width: 28, height: 28)
    }

    private func turnPriorityOff() {
        priorityActivationTask?.cancel()
        priorityActivationTask = nil
        isTurningPriorityOn = false
        if !excludedFromPriorityIds.contains(card.id) {
            excludedFromPriorityIds.append(card.id)
        }
        onSave()
    }

    private func beginTurningPriorityOn() {
        guard !isTurningPriorityOn else { return }
        priorityRingProgress = 0
        isTurningPriorityOn = true
        priorityActivationTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            excludedFromPriorityIds.removeAll { $0 == card.id }
            isTurningPriorityOn = false
            priorityActivationTask = nil
            onSave()
        }
    }

    /// The completion action shares a row with Priority at standard text sizes.
    private var doneButton: some View {
        Button {
            onClose()
            if isPriority { onCompletePriority(card) }
            else { onComplete(card) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .fontWeight(.heavy)
                    .frame(width: 28, height: 28)
                Text("Complete")
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
