import SwiftUI

/// The single editor used for both writing a new note and editing an existing
/// one. Creating and editing differed only in their chrome before, which left
/// the text surface, the hyphen-split segments and the segment-restore logic
/// duplicated; this owns all of it once.
///
/// Chrome follows the note's state: an empty note offers only Cancel, and the
/// undo and done controls appear as soon as there is something to keep.
struct NoteEditor: View {
    enum Mode {
        /// Writing something new. Offers a random prompt for a blank page.
        case create
        /// Reworking a note that already has content.
        case edit
    }

    @Binding var text: String
    var mode: Mode = .create
    var startWithDictation: Bool = false
    let onCancel: () -> Void
    let onSave: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("hyphenSplitEnabled") private var hyphenSplitEnabled: Bool = false
    @StateObject private var dictation = SpeechDictationManager()
    @StateObject private var controller = NoteEditorController()

    /// Text present when dictation began, so the live transcript extends it.
    @State private var baseText: String = ""
    /// Hyphen lines already committed as separate notes (Split by Hyphens on).
    @State private var committedSegments: [String] = []

    private var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !committedSegments.isEmpty
    }

    var body: some View {
        // The control row is stacked rather than inset so it lands on the same Y
        // as the preview's; `safeAreaInset(edge: .top)` places a row outside the
        // content's safe area and the two screens stopped lining up.
        VStack(spacing: 0) {
            NoteChromeRow { topControls }
            noteSurface
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Material.Surface.tertiary)
        .safeAreaInset(edge: .bottom) { dictateControls }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            baseText = text
            if startWithDictation {
                dictation.requestAuthorizationAndStart()
            } else {
                // Deferred: becoming first responder while the sheet is still
                // presenting is dropped.
                DispatchQueue.main.async { controller.focus() }
            }
        }
        .onDisappear { dictation.stop() }
        .onChange(of: text) { _, newValue in
            guard hyphenSplitEnabled else { return }
            let result = NoteSplitter.commitAfterNewline(newValue)
            guard !result.committed.isEmpty else { return }
            withAnimation(Motion.gated(.easeOut(duration: 0.2), reduce: reduceMotion)) {
                committedSegments.append(contentsOf: result.committed)
            }
            text = result.remaining
            baseText = result.remaining
        }
        .onChange(of: dictation.transcript) { _, newValue in
            text = SpeechDictationManager.compose(base: baseText, transcript: newValue)
        }
        .onChange(of: dictation.permissionDenied) { _, denied in
            if denied { controller.focus() }
        }
        .onChange(of: dictation.onDeviceUnavailable) { _, unavailable in
            if unavailable { controller.focus() }
        }
        .alert("Microphone access needed", isPresented: $dictation.permissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To capture notes with your voice, allow microphone and speech recognition access in Settings. You can still type your note.")
        }
        .alert("Dictation unavailable", isPresented: $dictation.onDeviceUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("On-device dictation isn't available for your language on this device. You can still type your note.")
        }
    }

    private var noteSurface: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(committedSegments.enumerated()), id: \.offset) { index, segment in
                Button { restoreSegments(from: index) } label: {
                    CommittedSegmentRow(segment: segment)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Merges this line and the ones below it back into the note")
                .accessibilityIdentifier("note-segment-\(index)")

                DashedDivider()
            }

            ZStack(alignment: .topLeading) {
                RichNoteTextView(text: $text, controller: controller)

                if text.isEmpty && committedSegments.isEmpty {
                    Text("What do you want to capture?")
                        .font(AppFont.body)
                        .foregroundColor(Material.Text.secondary)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Chrome

    /// Mounted inside `NoteChromeRow`, which owns the padding this row shares
    /// with the preview's.
    @ViewBuilder
    private var topControls: some View {
        Button("Cancel") {
            dictation.stop()
            committedSegments = []
            onCancel()
        }
        .buttonStyle(.editorCapsule)
        .accessibilityIdentifier("cancel-edit-button")

        Spacer(minLength: 0)

        // Nothing to undo or keep on a blank page, so the design holds these
        // back until the note has content.
        if hasContent {
            Button { controller.undo() } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.editorIcon)
            .disabled(!controller.canUndo)
            .accessibilityLabel("Undo")
            .accessibilityIdentifier("undo-note-button")

            Button(action: save) {
                Image(systemName: "checkmark")
            }
            .buttonStyle(.editorIcon)
            .accessibilityLabel("Save note")
            .accessibilityIdentifier("save-edit-button")
        }
    }

    private var dictateControls: some View {
        HStack(spacing: 12) {
            Button {
                if dictation.isRecording {
                    dictation.stop()
                } else {
                    baseText = text
                    dictation.requestAuthorizationAndStart()
                }
            } label: {
                Label(
                    dictation.isRecording ? "Stop" : "Dictate",
                    systemImage: dictation.isRecording ? "stop.fill" : "mic.fill"
                )
            }
            .buttonStyle(.editorCapsule)
            .accessibilityIdentifier("dictate-button")

            if dictation.isRecording {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(AppFont.icon)
                        .foregroundColor(Material.Text.accent)
                        // The "Listening…" label carries the state, so the
                        // perpetual pulse can go entirely.
                        .symbolEffect(.variableColor.iterative,
                                      options: .repeating,
                                      isActive: !Motion.isReduced(reduceMotion))
                    Text("Listening…")
                        .font(AppFont.caption)
                        .foregroundColor(Material.Text.secondary)
                }
            }

            Spacer(minLength: 0)

            if mode == .create {
                Button {
                    text = Self.randomSuggestions.randomElement() ?? ""
                } label: {
                    Image(systemName: "dice.fill")
                }
                .buttonStyle(.editorIcon)
                .accessibilityLabel("Generate")
                .accessibilityIdentifier("generate-note-button")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .background(Material.Surface.tertiary)
    }

    // MARK: - Actions

    /// Flattens any committed segments back into the text so callers only ever
    /// read `text`, then hands off to the owner to persist.
    private func save() {
        dictation.stop()
        if !committedSegments.isEmpty {
            text = NoteSplitter.canonicalText(segments: committedSegments, activeText: text)
            committedSegments = []
        }
        onSave()
    }

    /// Returns the tapped segment (and any after it, in order) to the editor as
    /// raw hyphen lines so the user can keep editing them.
    private func restoreSegments(from index: Int) {
        let restored = committedSegments[index...].map { "- " + $0 }.joined(separator: "\n")
        withAnimation(Motion.gated(.easeOut(duration: 0.2), reduce: reduceMotion)) {
            committedSegments.removeSubrange(index...)
        }
        text = restored + (text.isEmpty ? "" : "\n" + text)
        baseText = text
        controller.focus()
    }
}

/// A hyphen line already committed as its own note. Styled like the note it will
/// become: first line as the title, any remainder as body.
private struct CommittedSegmentRow: View {
    let segment: String

    var body: some View {
        let parts = segment.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        let title = parts.first.map(String.init) ?? ""
        let detail = parts.count > 1 ? String(parts[1]) : ""

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFont.title)
                .foregroundColor(Material.Text.primary)
            if !detail.isEmpty {
                Text(detail)
                    .font(AppFont.body)
                    .foregroundColor(Material.Text.secondary)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

/// Thin dashed separator between committed note segments.
private struct DashedDivider: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0.5))
                path.addLine(to: CGPoint(x: geo.size.width, y: 0.5))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .foregroundColor(Material.Decoration.tertiary)
        }
        .frame(height: 1)
    }
}

// MARK: - Random prompts

extension NoteEditor {
    /// Playful prompts offered by the dice control when creating a note, for
    /// when the blank page itself is the blocker.
    static let randomSuggestions = [
        String(localized: "Compliment your coffee mug ☕️",                      comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Name all the colors you can see 🌈",                 comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Count backwards from 10 in Spanish 🇪🇸",             comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Do a silly walk to the kitchen 🚶",                  comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Smell a lemon 🍋",                                   comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "High-five yourself 🙌",                              comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Whisper 'good job' to your plant 🪴",                comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Touch something blue 💙",                            comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Make a weird face in the mirror 😜",                 comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Pet an imaginary dog 🐕",                            comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Sing one word of your favorite song 🎵",             comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Stretch like a cat 🐱",                              comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Blink 20 times really fast 👁️",                      comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Say 'potato' in 3 different accents 🥔",             comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Spin around three times slowly 🌀",                  comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Name your shoes out loud 👟",                        comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Wave at something random 👋",                        comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Hum the Jeopardy theme 🎶",                          comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Balance on one foot for 10 seconds 🦩",              comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Make up a word and use it in a sentence 💭",         comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Count how many pens you have ✍️",                    comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Tap your nose 7 times 👃",                           comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Say the alphabet backwards from G 🔤",               comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Wiggle your toes 🦶",                                comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Name three things you're grateful for 🙏",           comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Do 5 jumping jacks 🤸",                              comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Drink a glass of water 💧",                          comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Take 3 deep breaths 🫁",                             comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Look out the window for 30 seconds 🪟",              comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Write your name with your non-dominant hand ✏️",     comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Snap your fingers 10 times 🫰",                      comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Touch your elbows together 💪",                      comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Make a bird sound 🐦",                               comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Pretend you're a robot for 15 seconds 🤖",           comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
        String(localized: "Organize one thing on your desk 📎",                 comment: "Playful random suggestion in create note screen — translate if culturally appropriate"),
    ]
}
