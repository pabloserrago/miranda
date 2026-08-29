import SwiftUI
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

/// The three mutually exclusive home screens.
enum HomeState {
    case empty
    case noPriority
    case list
}

/// Mutually exclusive age bands for the Recent sheet. Calendar-day boundaries
/// keep a note in the same section for the whole day, rather than moving it at
/// the exact minute it was created.
enum RecentNotesSection: Int, CaseIterable, Identifiable {
    case first30Days
    case previous30Days
    case previous3Months
    case previousYears

    var id: Self { self }

    var title: LocalizedStringKey? {
        switch self {
        case .first30Days: nil
        case .previous30Days: "Previous 30 Days"
        case .previous3Months: "Previous 3 Months"
        case .previousYears: "Previous Years"
        }
    }

    static func section(for date: Date, relativeTo now: Date, calendar: Calendar = .current) -> Self {
        let noteDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)
        let ageInDays = max(0, calendar.dateComponents([.day], from: noteDay, to: today).day ?? 0)

        switch ageInDays {
        case 0..<30: return .first30Days
        case 30..<90: return .previous30Days
        case 90..<365: return .previous3Months
        default: return .previousYears
        }
    }
}

/// Collects the rendered height of each priority row (keyed by index) so the
/// reorder drag can convert translation into slots using real row heights.
private struct PriorityRowHeightKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppIconManager.storageKey) private var selectedAppIconRaw = AppIconOption.default.rawValue
    @State private var cards: [Card] = []
    @State private var priorityCardIds: [UUID] = []
    @State private var selectedCard: Card? = nil
    @State private var showAnalytics: Bool = false
    @State private var showSettings: Bool = false
    @State private var showCreateModal: Bool = false
    @State private var newCardText: String = ""
    /// The note a save just wrote, previewed in place of the editor.
    @State private var savedCard: Card? = nil
    @State private var startWithDictation: Bool = false
    @State private var showDoNowDialog: Bool = false
    @State private var pendingCard: Card? = nil
    @State private var showPriorityPicker: Bool = false
    @State private var showCompleteTortoise: Bool = false
    @State private var showWidgetInstructions: Bool = false
    @State private var searchText: String = ""
    @State private var widgetOnboardingDismissed: Bool = false
    @State private var captureOnboardingDismissed: Bool = false
    @State private var excludedFromPriorityIds: [UUID] = []
    @State private var showRecentSheet: Bool = false
    @State private var showReviewPrompt: Bool = false
    /// First-launch onboarding cover; completion is persisted via the
    /// "hasCompletedOnboarding" UserDefaults key (set in completeOnboarding).
    @State private var showOnboarding: Bool = false
    /// Long-press–then–drag priority reorder (no list edit mode).
    @State private var priorityReorderLiftedId: UUID?
    @State private var priorityReorderLiftedIndex: Int?
    @State private var priorityReorderTranslation: CGSize = .zero
    /// Finger drift accumulated during the hold before the long press fires.
    /// Subtracted from all subsequent translations so the card starts at offset 0.
    @State private var priorityReorderDragBaseline: CGFloat = 0
    /// Slot the lifted card would land on if dropped now; ticks haptically when it changes.
    @State private var priorityReorderProjectedIndex: Int?
    /// Set between finger-up and the array commit: the card is springing into
    /// its target slot and scale/shadow are relaxing.
    @State private var priorityReorderSettlingId: UUID?
    /// Rendered height (including list insets) of each priority row, by index.
    @State private var priorityRowHeights: [Int: CGFloat] = [:]
    /// After a long-press reorder lifts a card, ignore the finger-up “tap” so the detail sheet does not open.
    @State private var suppressNextPrioritySelectionId: UUID?

    @State private var scrollOffset: CGFloat = 0

    /// Minimum list content-offset delta (pt) before toggling Recent sheet visibility.
    private let recentSheetScrollThreshold: CGFloat = 12

    @AppStorage("audioInputEnabled") private var audioInputEnabled: Bool = false
    @AppStorage("actionTransformEnabled") private var actionTransformEnabled: Bool = false
    @AppStorage("hyphenSplitEnabled") private var hyphenSplitEnabled: Bool = false
    @AppStorage("completionAnimationEnabled") private var completionAnimationEnabled: Bool = true
    @AppStorage(SharedCardManager.backgroundThemeKey, store: SharedCardManager.defaults)
    private var backgroundThemeRaw: String = BackgroundTheme.standard.rawValue
    init() {
        #if DEBUG
        if ContentView.isUITestLaunch {
            _cards = State(initialValue: ContentView.uiTestSeedCards)
            _widgetOnboardingDismissed = State(initialValue: true)
            _captureOnboardingDismissed = State(initialValue: true)
            _showRecentSheet = State(initialValue: false)
        }
        if ProcessInfo.processInfo.arguments.contains("-UITestNoPriorities") {
            // Every seeded card excluded, so home lands on the no-priority
            // state. The recent sheet stays open because that is the real
            // condition the CTA has to present a sheet over.
            _excludedFromPriorityIds = State(initialValue: ContentView.uiTestSeedCards.map(\.id))
            _showRecentSheet = State(initialValue: true)
        }
        if ProcessInfo.processInfo.arguments.contains("-UITestHyphenSplit") {
            // register(defaults:) is not persisted, so it cannot pollute later launches.
            UserDefaults.standard.register(defaults: ["hyphenSplitEnabled": true])
            // The create button lives in the recent sheet's toolbar.
            _showRecentSheet = State(initialValue: true)
        }
        if ProcessInfo.processInfo.arguments.contains("-UITestHyphenSplitEdit") {
            // Same setting as above, but leave the recent sheet closed so a
            // seeded priority note is directly tappable to reach Edit mode.
            UserDefaults.standard.register(defaults: ["hyphenSplitEnabled": true])
        }
        if ProcessInfo.processInfo.arguments.contains("-UITestShowOnboarding") {
            // Wipe persisted state so onboarding shows deterministically,
            // regardless of what earlier test runs left in the container.
            // `analytics_events` is included so the onboarding pixel assertions
            // read this run's log rather than a previous run's tail.
            for key in ["hasCompletedOnboarding", "cards", "priorityCardIds",
                        "excludedFromPriorityIds", "widgetOnboardingDismissed",
                        "captureOnboardingDismissed",
                        "analytics_events"] {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        #endif
        _showOnboarding = State(initialValue: ContentView.shouldShowOnboarding(
            hasCompleted: UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"),
            hasPersistedCards: UserDefaults.standard.data(forKey: "cards") != nil,
            arguments: ProcessInfo.processInfo.arguments
        ))
    }

    /// Onboarding shows only on a fresh install: never completed and no
    /// existing cards (so users upgrading from pre-onboarding versions skip
    /// it). UI-test launches suppress it unless they explicitly request it.
    static func shouldShowOnboarding(
        hasCompleted: Bool,
        hasPersistedCards: Bool,
        arguments: [String]
    ) -> Bool {
        if arguments.contains("-UITestShowOnboarding") { return true }
        if arguments.contains(where: { $0.hasPrefix("-UITest") }) { return false }
        return !hasCompleted && !hasPersistedCards
    }

    /// Home renders the capture prompt with no notes at all, the priority
    /// prompt when every note has been excluded, and the list otherwise.
    static func homeState(hasCards: Bool, hasPriorities: Bool) -> HomeState {
        if !hasCards { return .empty }
        return hasPriorities ? .list : .noPriority
    }

    /// Whether completing a priority should re-offer the picker. Counts the
    /// visible priorities, not `priorityCardIds`, which retains ids of notes
    /// that have since been excluded.
    static func shouldOfferPicker(priorityCount: Int, cardsEmpty: Bool) -> Bool {
        PriorityNoteActions.canPromoteToPriority(currentPriorityCount: priorityCount) && !cardsEmpty
    }

    // MARK: - Computed Properties

    private var sortedCards: [Card] {
        cards.sorted { card1, card2 in
            let index1 = priorityCardIds.firstIndex(of: card1.id)
            let index2 = priorityCardIds.firstIndex(of: card2.id)
            if let idx1 = index1, let idx2 = index2 { return idx1 < idx2 }
            if index1 != nil { return true }
            if index2 != nil { return false }
            return card1.timestamp > card2.timestamp
        }
    }

    private var priorityCards: [Card] {
        priorityCardIds.compactMap { id in cards.first { $0.id == id } }
    }

    private var autoPriorityCardIds: Set<UUID> {
        Set(sortedCards.filter { !excludedFromPriorityIds.contains($0.id) }.map { $0.id })
    }

    private var autoPriorityCards: [Card] {
        sortedCards.filter { !excludedFromPriorityIds.contains($0.id) }
    }

    private var widgetPriorityCards: [Card] {
        Array(autoPriorityCards.prefix(3))
    }

    private var filteredNonPriorityCards: [Card] {
        let nonPriority = sortedCards.filter { !autoPriorityCardIds.contains($0.id) }
        if searchText.isEmpty { return nonPriority }
        return nonPriority.filter {
            $0.simplifiedText.localizedCaseInsensitiveContains(searchText) ||
            $0.originalText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var recentNoteSections: [(section: RecentNotesSection, cards: [Card])] {
        let now = Date()
        let grouped = Dictionary(grouping: filteredNonPriorityCards) {
            RecentNotesSection.section(for: $0.timestamp, relativeTo: now)
        }
        return RecentNotesSection.allCases.compactMap { section in
            guard let cards = grouped[section], !cards.isEmpty else { return nil }
            return (section, cards.sorted { $0.timestamp > $1.timestamp })
        }
    }

    private let emojiMap: [String: String] = {
        guard let url = Bundle.main.url(forResource: "EmojiMap", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return map
    }()

    private let actionTransformations: [String: String] = {
        guard let url = Bundle.main.url(forResource: "ActionTransformations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return map
    }()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                NoisyBackgroundView(
                    config: colorScheme == .dark ? .defaultDark : .default,
                    scrollOffset: scrollOffset,
                    theme: BackgroundTheme(rawValue: backgroundThemeRaw) ?? .standard
                ).ignoresSafeArea()

                switch ContentView.homeState(
                    hasCards: !cards.isEmpty,
                    hasPriorities: !autoPriorityCards.isEmpty
                ) {
                case .empty: emptyState
                case .noPriority: noPriorityState
                case .list: cardList
                }
            }
            .simultaneousGesture(recentSheetDragGesture)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Text("🐢")
                            .font(.system(size: 24.2))
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("settings-button")
                }
                ToolbarItem(placement: .principal) {
                    Text("Miranda First")
                        .font(AppFont.headline)
                        .foregroundColor(Material.Text.primary)
                        .accessibilityIdentifier("home-title")
                }
            }
        }
        .tint(Material.Text.accent)
        .onAppear {
            // Warm the Taptic Engine so the reorder lift thud plays without
            // delay (there is no press-time prepare anymore — touch-down side
            // effects broke the List's scroll and swipe recognizers).
            Haptics.prepareReorderLift()
            #if DEBUG
            if ContentView.isUITestLaunch {
                Analytics.shared.trackAppOpened()
                return
            }
            #endif
            loadState()
            Analytics.shared.trackAppOpened()
            // scenePhase is already .active on a cold launch, so its onChange
            // never fires for the first foreground.
            Task { await Analytics.shared.refreshWidgetInventory() }
            showRecentSheet = !cards.isEmpty
        }
        .onChange(of: cards) { _, _ in
            saveState()
        }
        .onChange(of: cards.isEmpty) { wasEmpty, isEmpty in
            if isEmpty {
                showRecentSheet = false
            } else if wasEmpty, !showOnboarding {
                showRecentSheet = true
            }
        }
        .onChange(of: cards.count) { oldCount, newCount in
            if newCount > oldCount, !cards.isEmpty, !showOnboarding {
                showRecentSheet = true
            }
        }
        .onChange(of: priorityCardIds) { _, _ in saveState() }
        .onChange(of: autoPriorityCards.isEmpty) { _, isEmpty in
            // The offset is only published while the list exists, so reset it
            // to keep the background parallax from freezing mid-scroll.
            if isEmpty {
                scrollOffset = 0
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // App Intents can update notes while Miranda is suspended.
                // Reload the complete persisted state instead of retaining the
                // stale @State values that were captured before suspension.
                loadState()
                NotificationManager.shared.syncAuthorizationStatus()
                AppIconManager.apply(AppIconOption(rawValue: selectedAppIconRaw) ?? .default, for: colorScheme)
                Task { await Analytics.shared.refreshWidgetInventory() }
            }
        }
        .onOpenURL { url in
            guard url.scheme == "miranda" else { return }
            if let destination = Analytics.widgetDestination(for: url) {
                Analytics.shared.trackWidgetOpened(destination: destination)
            }
            if url.host == "capture" {
                openCreateEditor()
            } else if url.host == "card",
                      let cardIdString = url.pathComponents.last,
                      let cardId = UUID(uuidString: cardIdString),
                      let card = cards.first(where: { $0.id == cardId }) {
                selectedCard = card
            }
        }
        .sheet(item: $selectedCard) { card in
            NoteDetailView(
                card: card,
                cards: $cards,
                excludedFromPriorityIds: $excludedFromPriorityIds,
                autoPriorityCardIds: autoPriorityCardIds,
                onSave: saveState,
                onComplete: completeCard,
                onCompletePriority: completePriorityCard,
                onClose: { selectedCard = nil },
                onNewNote: {
                    selectedCard = nil
                    // Deferred: dismissing this sheet and presenting the editor
                    // in the same update drops the second presentation.
                    DispatchQueue.main.async { openCreateEditor() }
                }
            )
            .presentationBackground(Material.Surface.secondary)
        }
        .sheet(isPresented: $showCompleteTortoise, onDismiss: {
            showCompleteTortoise = false
        }) {
            completionSheet
        }
        .sheet(isPresented: $showAnalytics) {
            AnalyticsDebugView()
                .presentationBackground(Material.Surface.secondary)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                onShowAnalytics: {
                    showSettings = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showAnalytics = true }
                },
                onDeleteAll: { clearAllCards() },
                onResetOnboarding: { resetOnboarding() },
                onEnableReminders: {
                    NotificationManager.shared.enableReminders(cards: widgetPriorityCards)
                },
                currentPriorityCard: priorityCards.first,
                lastCapture: cards.max(by: { $0.timestamp < $1.timestamp }),
                hasCaptures: !cards.isEmpty,
                onSendTestReminder: {
                    #if DEBUG
                    NotificationManager.shared.sendTestReminder(cards: widgetPriorityCards)
                    #endif
                }
            )
            .presentationBackground(Material.Surface.secondary)
        }
        .sheet(isPresented: $showWidgetInstructions) {
            NavigationStack {
                HowToAddWidgetView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showWidgetInstructions = false }
                        }
                    }
            }
            .presentationBackground(Material.Surface.secondary)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(
                newCardText: $newCardText,
                latestCard: widgetPriorityCards.first,
                onSaveNote: { createCard() },
                onFinish: { completeOnboarding() }
            )
        }
        .sheet(isPresented: $showCreateModal, onDismiss: { savedCard = nil }) {
            Group {
                // Saving swaps the editor for the note it just wrote, so the
                // capture is confirmed without a second sheet.
                if let card = savedCard {
                    NoteDetailView(
                        card: card,
                        cards: $cards,
                        excludedFromPriorityIds: $excludedFromPriorityIds,
                        autoPriorityCardIds: autoPriorityCardIds,
                        onSave: saveState,
                        onComplete: completeCard,
                        onCompletePriority: completePriorityCard,
                        onClose: {
                            savedCard = nil
                            showCreateModal = false
                        },
                        onNewNote: {
                            // Same sheet, back to a blank page — no dismissal to
                            // sequence.
                            savedCard = nil
                            newCardText = ""
                            startWithDictation = false
                        }
                    )
                } else {
                    NoteEditor(
                        text: $newCardText,
                        mode: .create,
                        startWithDictation: startWithDictation,
                        onCancel: {
                            newCardText = ""
                            showCreateModal = false
                            startWithDictation = false
                        },
                        onSave: { createCard() }
                    )
                }
            }
            .presentationBackground(Material.Surface.secondary)
        }
        .sheet(isPresented: $showPriorityPicker) {
            PriorityPickerView(
                cards: cards.sorted { $0.timestamp > $1.timestamp }
                    .filter { !autoPriorityCardIds.contains($0.id) },
                onSelect: { card in
                    guard PriorityNoteActions.canPromoteToPriority(
                        currentPriorityCount: autoPriorityCards.count
                    ) else { return }
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    // Home reads the exclusion list, so the note has to be
                    // un-excluded as well as ordered.
                    excludedFromPriorityIds = PriorityNoteActions.includeInPriority(
                        cardId: card.id, excludedIds: excludedFromPriorityIds
                    )
                    addToPriorities(card.id)
                    saveState()
                    showPriorityPicker = false
                },
                onCaptureText: {
                    openCreateEditor()
                },
                onCaptureVoice: {
                    openCreateEditor(dictating: true)
                }
            )
            .presentationBackground(Material.Surface.secondary)
        }
        .alert("Do you want to focus on achieving this?", isPresented: $showDoNowDialog) {
            Button("Yes, let's go!", role: .none) {
                if let card = pendingCard {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    cards.append(card)
                    addToPriorities(card.id)
                    Analytics.shared.trackCardCreated(hasEmoji: card.emoji != nil)
                    pendingCard = nil
                }
            }
            Button("Maybe later", role: .cancel) {
                if let card = pendingCard {
                    cards.append(card)
                    Analytics.shared.trackCardCreated(hasEmoji: card.emoji != nil)
                    pendingCard = nil
                }
            }
        } message: {
            if let card = pendingCard {
                Text("\(card.emoji ?? "")  \(card.simplifiedText)")
            }
        }
        .sheet(isPresented: $showRecentSheet) {
            recentSheet
        }
        .sheet(isPresented: $showReviewPrompt) {
            ReviewPromptView()
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            if !captureOnboardingDismissed {
                VStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation { captureOnboardingDismissed = true }
                            saveState()
                        } label: {
                            Image(systemName: "xmark")
                                .font(AppFont.caption).fontWeight(.medium)
                                .foregroundColor(Material.Text.secondary)
                        }
                        .accessibilityLabel("Dismiss tip")
                    }
                    Group {
                        Text("Capture anything that's in your mind. Like a dream, idea or to-do. ")
                        + Text("Simple.").bold()
                    }
                    .font(AppFont.body)
                    .foregroundColor(Material.Text.primary)
                }
                .padding(25)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(Material.Card.onboarding, from: .top, to: .bottom)
                .padding(.horizontal, 20)
            }

            Button {
                openCreateEditor()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Note")
                }
            }
            .primaryButtonStyle()

            Spacer()
        }
    }

    /// Notes exist but every one of them has been excluded, so the priority
    /// list would otherwise render blank with no way back in.
    @ViewBuilder
    private var noPriorityState: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("Nothing set as priority")
                    .font(AppFont.headline)
                    .foregroundColor(Material.Text.primary)
                Text("Pick one note to focus on right now")
                    .font(AppFont.body)
                    .foregroundColor(Material.Text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button { presentPriorityPicker() } label: {
                Text("Turn On a Priority")
            }
            .primaryButtonStyle()
            .accessibilityIdentifier("turn-on-priority-button")

            Spacer()
        }
    }

    // MARK: - Card List

    private var recentSheetDragGesture: some Gesture {
        DragGesture(minimumDistance: recentSheetScrollThreshold)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dy) > abs(dx) else { return }
                if dy < 0 {
                    showRecentSheet = false
                } else if dy > 0 {
                    if !cards.isEmpty { showRecentSheet = true }
                }
            }
    }

    @ViewBuilder
    private var cardList: some View {
        List {
            if !widgetOnboardingDismissed && !autoPriorityCards.isEmpty && autoPriorityCards.count < 3 {
                Section {
                    widgetOnboardingRow
                }
            }

            if !autoPriorityCards.isEmpty {
                Section {
                    ForEach(Array(autoPriorityCards.enumerated()), id: \.element.id) { index, card in
                        priorityRow(
                            card,
                            index: index,
                            allowDragReorder: autoPriorityCards.count > 1
                        )
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        // Collapse the plain List's default section spacing above the first
        // card, then set the gap explicitly: 14 + the first row's 10pt top
        // inset = 24px below the nav bar.
        .listSectionSpacing(0)
        .contentMargins(.top, 14, for: .scrollContent)
        // Scroll position for the background parallax. Replaces the old
        // zero-height anchor row, which couldn't shrink below the List's
        // default minimum row height and pushed the first card down ~44pt.
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y + geo.contentInsets.top
        } action: { _, offset in
            scrollOffset = max(0, offset)
        }
        .onPreferenceChange(PriorityRowHeightKey.self) { heights in
            priorityRowHeights = heights
        }
        // Disable list scrolling only while a card is lifted so the DragGesture
        // can track vertical movement without competing with the scroll view.
        // Keying this on the pre-lift pressing state breaks swipe actions:
        // pressing begins at touch-down, and toggling scrollDisabled mid-touch
        // kills the swipe pan for any swipe that starts with a brief rest.
        .scrollDisabled(priorityReorderLiftedId != nil)
        // DragGesture lives at the List level (above individual cells) so it:
        //   1. Always receives ongoing touches that started on any row, and
        //   2. Never competes with cell-level swipe action pan recognizers.
        // minimumDistance must stay ≥ 10: at 0 the gesture swallows taps on
        // the UIKit swipe-action buttons (Remove/Delete stop responding).
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    guard priorityReorderLiftedId != nil, priorityReorderSettlingId == nil else { return }
                    if priorityReorderTranslation == .zero && priorityReorderDragBaseline == 0 {
                        // First update after lift: zero-out any drift accumulated during the hold.
                        priorityReorderDragBaseline = value.translation.height
                    }
                    let calibrated = value.translation.height - priorityReorderDragBaseline
                    priorityReorderTranslation = CGSize(width: 0, height: calibrated)

                    if let source = priorityReorderLiftedIndex {
                        let projected = projectedPriorityIndex(sourceIndex: source, translationHeight: calibrated)
                        if projected != priorityReorderProjectedIndex {
                            priorityReorderProjectedIndex = projected
                            Haptics.reorderTick()
                        }
                    }
                }
                .onEnded { value in
                    guard let source = priorityReorderLiftedIndex, priorityReorderSettlingId == nil else { return }
                    // Fold in any movement the last onChanged missed before settling.
                    let calibrated = value.translation.height - priorityReorderDragBaseline
                    priorityReorderProjectedIndex = projectedPriorityIndex(sourceIndex: source, translationHeight: calibrated)
                    settleLiftedPriorityCard()
                }
        )
    }

    /// Drops the lifted card: springs it into the projected slot, then swaps
    /// the array once the spring lands. Called from the drag's onEnded and —
    /// for a lift released without any drag — from the row Button's tap
    /// (touch-up fires the Button even after a long stationary hold).
    private func settleLiftedPriorityCard() {
        guard let idx = priorityReorderLiftedIndex, priorityReorderSettlingId == nil else { return }
        let capturedId = priorityReorderLiftedId
        let target = priorityReorderProjectedIndex ?? idx

        // Phase 1: spring the lifted card into the gap the live shuffle
        // opened; settlingId relaxes its scale and shadow.
        priorityReorderSettlingId = capturedId
        priorityReorderTranslation = CGSize(
            width: 0,
            height: settleTranslationForDrop(sourceIndex: idx, targetIndex: target)
        )

        // Phase 2: once the spring lands, swap the array without animation —
        // the reordered layout is pixel-identical to the settled visuals, so
        // nothing on screen moves.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                movePriorityFromIndex(from: idx, to: target)
                priorityReorderLiftedId = nil
                priorityReorderLiftedIndex = nil
                priorityReorderTranslation = .zero
                priorityReorderDragBaseline = 0
                priorityReorderProjectedIndex = nil
                priorityReorderSettlingId = nil
            }
            Haptics.prepareReorderLift()
        }
        if let id = capturedId {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if suppressNextPrioritySelectionId == id {
                    suppressNextPrioritySelectionId = nil
                }
            }
        }
    }

    @ViewBuilder
    private var widgetOnboardingRow: some View {
        Button { showWidgetInstructions = true } label: {
            VStack(alignment: .leading) {
                Group {
                    Text("Add the Widget to your home screen to keep your priorities visible. ")
                    + Text("Easy-peasy.").bold()
                }
                .font(AppFont.body)
                .foregroundColor(Material.Text.primary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .cardSurface(Material.Card.onboarding, from: .top, to: .bottom)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation { widgetOnboardingDismissed = true }
                saveState()
            } label: {
                Label("Dismiss", systemImage: "xmark")
            }
        }
    }

    // MARK: - Recent Sheet

    private var recentSheet: some View {
        recentSheetContent
            .tint(Material.Accent.primary)
            .presentationDetents([.fraction(0.25), .medium, .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .modifier(RecentSheetBackground())
            .interactiveDismissDisabled()
            .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var recentSheetContent: some View {
        if #available(iOS 26.0, *) {
            recentSheetGlass
        } else {
            recentSheetNative
        }
    }

    // Custom floating Liquid Glass chrome (iOS 26+): a glass mic/plus pill and a
    // glass "Find..." search bar, matching Pages-style floating controls.
    @available(iOS 26.0, *)
    private var recentSheetGlass: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent")
                    .font(AppFont.headline)
                    .foregroundColor(Material.Text.primary)
                Spacer()
                recentGlassActionPill
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)

            List {
                ForEach(recentNoteSections, id: \.section) { group in
                    Section {
                        ForEach(group.cards) { card in
                            recentRow(card)
                        }
                    } header: {
                        if let title = group.section.title {
                            Text(title)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .overlay { recentEmptyState }
        }
        .safeAreaInset(edge: .bottom) { recentGlassSearchBar }
    }

    @available(iOS 26.0, *)
    private var recentGlassActionPill: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                if audioInputEnabled {
                    Button {
                        openCreateEditor(dictating: true)
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(AppFont.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Material.Icon.action)
                            .frame(width: 50, height: 50)
                            .contentShape(Circle())
                    }
                    .glassEffect(.regular.interactive(), in: Circle())
                    .accessibilityLabel("Dictate note")
                    .accessibilityIdentifier("dictate-note-button")
                }
                Button {
                    openCreateEditor()
                } label: {
                    Image(systemName: "plus")
                        .font(AppFont.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Material.Icon.action)
                        .frame(width: 50, height: 50)
                        .contentShape(Circle())
                }
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel("New note")
                .accessibilityIdentifier("create-note-button")
            }
        }
    }

    @available(iOS 26.0, *)
    private var recentGlassSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Material.Text.secondary)
            TextField("Find...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(Material.Text.primary)
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Material.Text.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .font(AppFont.body)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var recentEmptyState: some View {
        if filteredNonPriorityCards.isEmpty {
            VStack(spacing: 12) {
                Text(searchText.isEmpty ? "All caught up" : "No results")
                    .font(AppFont.body)
                    .foregroundColor(Material.Text.secondary)
            }
        }
    }

    private var recentSheetNative: some View {
        NavigationStack {
            List {
                ForEach(recentNoteSections, id: \.section) { group in
                    Section {
                        ForEach(group.cards) { card in
                            recentRow(card)
                        }
                    } header: {
                        if let title = group.section.title {
                            Text(title)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .overlay { recentEmptyState }
            .navigationTitle("Recent")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Find...")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if audioInputEnabled {
                        Button {
                            openCreateEditor(dictating: true)
                        } label: {
                            Image(systemName: "mic.fill")
                                .foregroundStyle(Material.Icon.action)
                        }
                        .accessibilityLabel("Dictate note")
                        .accessibilityIdentifier("dictate-note-button")
                    }
                    Button {
                        openCreateEditor()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Material.Icon.action)
                    }
                    .accessibilityLabel("New note")
                    .accessibilityIdentifier("create-note-button")
                }
            }
        }
    }

    // MARK: - Priority Row (gradient card)

    @ViewBuilder
    private func priorityRow(_ card: Card, index: Int = 0, allowDragReorder: Bool = false) -> some View {
        let liftedHere = priorityReorderLiftedId == card.id
        let settlingHere = priorityReorderSettlingId == card.id
        let reorderActiveElsewhere = allowDragReorder && priorityReorderLiftedId != nil && priorityReorderLiftedId != card.id
        // Live shuffle: non-lifted rows part around the drag so the drop gap is visible.
        let shuffleY: CGFloat = {
            guard !liftedHere,
                  let source = priorityReorderLiftedIndex,
                  let target = priorityReorderProjectedIndex else { return 0 }
            let liftedHeight = priorityRowHeights[source] ?? priorityReorderRowStride
            return PriorityReorderMath.shuffleOffset(
                rowIndex: index,
                sourceIndex: source,
                targetIndex: target,
                liftedHeight: liftedHeight
            )
        }()

        Button {
            // A lift released without any drag never activates the reorder
            // DragGesture (10pt minimum), but touch-up still fires this
            // action — use it as the drop signal so the state can't get stuck.
            if priorityReorderLiftedId == card.id {
                settleLiftedPriorityCard()
                return
            }
            guard priorityReorderLiftedId == nil else { return }
            if suppressNextPrioritySelectionId == card.id {
                suppressNextPrioritySelectionId = nil
                return
            }
            selectedCard = card
        } label: {
            Text(card.simplifiedText)
                .font(AppFont.priority)
                .foregroundColor(Material.Text.primary)
                .multilineTextAlignment(.leading)
                // Uncapped at accessibility sizes so the card grows instead of
                // truncating the note. minHeight is a floor, not a clip.
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 4)
                .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(card.simplifiedText)
        .accessibilityIdentifier("priority-note-\(card.id.uuidString)")
        .accessibilityHint(allowDragReorder ? "Long press, then drag up or down to reorder" : "")
        // The lift-and-drag reorder is unreachable without precise pointing, so
        // the same operation is exposed as named actions for Voice Control,
        // VoiceOver, Switch Control, and Full Keyboard Access.
        .accessibilityActions {
            if allowDragReorder {
                if index > 0 {
                    Button("Move Up") { movePriorityCard(card, to: index - 1) }
                }
                if index < autoPriorityCards.count - 1 {
                    Button("Move Down") { movePriorityCard(card, to: index + 1) }
                }
            }
        }
        // simultaneousGesture, NOT .onLongPressGesture: on a Button the plain
        // long press loses gesture arbitration to the button's own press and
        // only fires once movement cancels it — a stationary hold never lifted.
        .simultaneousGesture(
            // 15pt tolerance: since scrolling stays enabled until the lift,
            // any real swipe or scroll drift must cancel the pending lift fast.
            // No .updating closure: mutating state (and animating the cell)
            // at touch-down disrupts the List's scroll and swipe-action pans
            // for every touch that starts on a card.
            LongPressGesture(minimumDuration: 0.35, maximumDistance: 15)
                .onEnded { _ in
                    guard allowDragReorder, priorityReorderSettlingId == nil else { return }
                    Haptics.reorderLift()
                    suppressNextPrioritySelectionId = card.id
                    priorityReorderLiftedId = card.id
                    priorityReorderLiftedIndex = index
                    priorityReorderProjectedIndex = index
                }
        )
        .cardSurface(
            Material.Card.colors(for: index),
            borderColor: Material.Card.border,
            borderWidth: Material.Card.borderWidth
        )
        .background(GeometryReader { geo in
            // +20 accounts for the 10pt top/bottom list row insets below.
            Color.clear.preference(key: PriorityRowHeightKey.self, value: [index: geo.size.height + 20])
        })
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { removePriorityCard(card) } label: {
                Label {
                    Text("Priority")
                } icon: {
                    Image(uiImage: prioritySwipeIcon("lightbulb.slash.fill"))
                }
            }
            .tint(Material.Status.warning)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { deleteCard(card) } label: {
                Label {
                    Text("Delete")
                        .foregroundStyle(Material.Text.onDestructive)
                } icon: {
                    Image(uiImage: deleteSwipeIcon)
                }
            }
            .tint(Material.Control.destructiveFill)
            Button { completePriorityCard(card) } label: {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(Material.Accent.primary)
        }
        .offset(y: liftedHere ? priorityReorderTranslation.height : shuffleY)
        // Shuffle spring only while a lift is active; at the array commit the
        // offsets reset to zero and must NOT animate (the layout swap already
        // places every row where its offset had it — animating would double-move).
        .animation(
            Motion.gated(
                priorityReorderLiftedId != nil ? .spring(response: 0.32, dampingFraction: 0.8) : nil,
                reduce: reduceMotion
            ),
            value: shuffleY
        )
        // The lift already reads through shadow and z-order; the scale is pure
        // motion, so Reduce Motion drops it.
        .scaleEffect(liftedHere && !settlingHere && !Motion.isReduced(reduceMotion) ? 1.06 : 1.0)
        .opacity(reorderActiveElsewhere ? 0.55 : 1)
        .zIndex(liftedHere ? 1 : 0)
        // Interactive spring tracks the finger and springs the drop into its
        // slot; nil after commit so the offset reset never animates.
        .animation(
            Motion.gated(
                liftedHere ? .interactiveSpring(response: 0.28, dampingFraction: 0.82) : nil,
                reduce: reduceMotion
            ),
            value: priorityReorderTranslation
        )
        .animation(Motion.gated(.spring(response: 0.3, dampingFraction: 0.85), reduce: reduceMotion),
                   value: settlingHere)
        .animation(Motion.gated(.spring(response: 0.25, dampingFraction: 0.92), reduce: reduceMotion),
                   value: liftedHere)
        .shadow(
            color: liftedHere && !settlingHere ? Material.Elevation.shadow.opacity(0.32) : .clear,
            radius: liftedHere && !settlingHere ? 28 : 0,
            x: 0,
            y: liftedHere && !settlingHere ? 18 : 0
        )
    }

    // MARK: - Recent Row (subtle card)

    @ViewBuilder
    private func recentRow(_ card: Card) -> some View {
        Button { selectedCard = card } label: {
            Text(card.simplifiedText)
                .font(AppFont.body)
                .foregroundColor(Material.Text.primary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recent-note-\(card.id.uuidString)")
        .cardSurface([Material.Surface.secondary], shadow: false, glass: false)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { deleteCard(card) } label: {
                Label {
                    Text("Delete")
                        .foregroundStyle(Material.Text.onDestructive)
                } icon: {
                    Image(uiImage: deleteSwipeIcon)
                }
            }
            .tint(Material.Control.destructiveFill)
            Button { completeCard(card) } label: {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(Material.Accent.primary)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                withAnimation { excludedFromPriorityIds.removeAll { $0 == card.id } }
                saveState()
                maybePromptReview()
            } label: {
                Label {
                    Text("Priority")
                } icon: {
                    Image(uiImage: prioritySwipeIcon("lightbulb.fill"))
                }
            }
            .tint(Material.Status.warning)
        }
    }

    /// Native swipe actions force template symbols to white. Supplying an
    /// original-rendering image keeps Priority's bulb black in both appearances.
    private func prioritySwipeIcon(_ systemName: String) -> UIImage {
        UIImage(systemName: systemName)?
            .withTintColor(Material.Text.onWarningUIColor, renderingMode: .alwaysOriginal)
            ?? UIImage()
    }

    private var deleteSwipeIcon: UIImage {
        UIImage(systemName: "trash")?
            .withTintColor(Material.Text.onDestructiveUIColor, renderingMode: .alwaysOriginal)
            ?? UIImage()
    }

    // MARK: - Note Detail

    @ViewBuilder

    // MARK: - Completion Celebration

    private var completionSheet: some View {
        VStack(spacing: 16) {
            Text("🐢").font(.system(size: 60))
            Text("winning slow and steady!")
                .font(AppFont.headline)
                .foregroundColor(Material.Text.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .accessibilityIdentifier("completion-celebration")
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Material.Surface.secondary)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showCompleteTortoise = false
                schedulePriorityPickerIfNeededAfterCompletion()
            }
        }
    }

    /// After a priority is completed, offer the picker when there is room for more priorities.
    private func schedulePriorityPickerIfNeededAfterCompletion() {
        guard ContentView.shouldOfferPicker(
            priorityCount: autoPriorityCards.count,
            cardsEmpty: cards.isEmpty
        ) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { presentPriorityPicker() }
    }

    /// Only one sheet can be presented from this view at a time, so the recent
    /// sheet has to close before the picker will appear.
    private func presentPriorityPicker() {
        showRecentSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showPriorityPicker = true }
    }

    // MARK: - Reorder

    /// Approximate row stride (card + list insets) for mapping drag distance to index delta.
    private let priorityReorderRowStride: CGFloat = 125

    private func movePriorityFromIndex(from: Int, to: Int) {
        guard from != to else { return }
        let count = autoPriorityCards.count
        guard from >= 0, to >= 0, from < count, to < count else { return }
        syncPriorityOrder()
        priorityCardIds = PriorityReorderMath.reordered(
            autoPriorityCards.map(\.id), from: from, to: to
        )
        saveState()
    }

    /// Pointer-free equivalent of the drag reorder, driven by the row's
    /// Move Up / Move Down accessibility actions. Skips the lift-and-settle
    /// animation entirely and commits the new order directly.
    private func movePriorityCard(_ card: Card, to destination: Int) {
        guard let source = autoPriorityCards.firstIndex(where: { $0.id == card.id }) else { return }
        movePriorityFromIndex(from: source, to: destination)
        Haptics.reorderTick()
    }

    /// Converts a drag translation into the slot the lifted card would land on,
    /// preferring measured row heights so the result matches what the user sees.
    private func projectedPriorityIndex(sourceIndex: Int, translationHeight: CGFloat) -> Int {
        let count = autoPriorityCards.count
        let measured = (0..<count).compactMap { priorityRowHeights[$0] }
        if measured.count == count {
            return PriorityReorderMath.targetIndex(
                sourceIndex: sourceIndex,
                translationHeight: translationHeight,
                rowHeights: measured
            )
        }
        return PriorityReorderMath.targetIndex(
            sourceIndex: sourceIndex,
            translationHeight: translationHeight,
            rowStride: priorityReorderRowStride,
            count: count
        )
    }

    /// Translation at which the lifted card sits exactly in its target slot,
    /// preferring measured heights (same fallback as projectedPriorityIndex).
    private func settleTranslationForDrop(sourceIndex: Int, targetIndex: Int) -> CGFloat {
        let count = autoPriorityCards.count
        let measured = (0..<count).compactMap { priorityRowHeights[$0] }
        if measured.count == count {
            return PriorityReorderMath.settleTranslation(
                sourceIndex: sourceIndex,
                targetIndex: targetIndex,
                rowHeights: measured
            )
        }
        return CGFloat(targetIndex - sourceIndex) * priorityReorderRowStride
    }

    // MARK: - Card Actions

    /// Opens the editor on a blank page. Shared so every entry point resets the
    /// same state — a stale `savedCard` would open on a preview instead.
    private func openCreateEditor(dictating: Bool = false) {
        savedCard = nil
        newCardText = ""
        startWithDictation = dictating
        showCreateModal = true
    }

    private func createCard() {
        guard !newCardText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let noteTexts = hyphenSplitEnabled ? NoteSplitter.split(newCardText) : [newCardText]
        var created: [Card] = []
        for originalText in noteTexts {
            let actionText = actionTransformEnabled ? transformToAction(originalText) : originalText
            let newCard = Card(
                originalText: originalText,
                simplifiedText: actionText,
                emoji: nil,
                timestamp: Date()
            )
            cards.append(newCard)
            created.append(newCard)
            let currentPriorityCount = cards.filter { !excludedFromPriorityIds.contains($0.id) }.count
            if currentPriorityCount > 3 { excludedFromPriorityIds.append(newCard.id) }
            Analytics.shared.trackCardCreated(hasEmoji: false)
        }
        newCardText = ""

        // A save that split into several notes has no single note to show, and
        // onboarding drives its own screen, so both close the way they always did.
        if created.count == 1 && showCreateModal {
            savedCard = created.first
        } else {
            showCreateModal = false
        }
    }

    private func completeCard(_ card: Card) {
        let timeToComplete = Date().timeIntervalSince(card.timestamp)
        Analytics.shared.trackCardCompleted(timeToComplete: timeToComplete)
        withAnimation {
            cards.removeAll { $0.id == card.id }
            priorityCardIds.removeAll { $0 == card.id }
        }
        maybePromptReview()
    }

    private func deleteCard(_ card: Card) {
        withAnimation {
            let updated = PriorityNoteActions.removeCard(
                id: card.id,
                from: cards,
                priorityIds: priorityCardIds
            )
            cards = updated.cards
            priorityCardIds = updated.priorityIds
        }
        saveState()
    }

    private func removePriorityCard(_ card: Card) {
        withAnimation {
            excludedFromPriorityIds = PriorityNoteActions.excludeFromPriority(
                cardId: card.id,
                excludedIds: excludedFromPriorityIds
            )
        }
        saveState()
    }

    private func completePriorityCard(_ card: Card) {
        let timeToComplete = Date().timeIntervalSince(card.timestamp)
        Analytics.shared.trackCardCompleted(timeToComplete: timeToComplete)
        withAnimation {
            cards.removeAll { $0.id == card.id }
            priorityCardIds.removeAll { $0 == card.id }
        }
        maybePromptReview()
        // The celebration is a full-screen animated flourish, so the system
        // setting overrides the user's preference for it.
        if completionAnimationEnabled && !Motion.isReduced(reduceMotion) {
            // Reset first so a stuck `true` (e.g. sheet dismissed while another sheet was open)
            // still triggers a fresh presentation when the user turns the toggle back on.
            showCompleteTortoise = false
            DispatchQueue.main.async {
                showCompleteTortoise = true
            }
        } else {
            showCompleteTortoise = false
            schedulePriorityPickerIfNeededAfterCompletion()
        }
    }

    private func maybePromptReview() {
        Task {
            guard await ReviewManager.shared.shouldShowPrompt() else { return }
            let attempt = ReviewManager.shared.currentAttemptNumber
            ReviewManager.shared.recordPromptShown()
            Analytics.shared.trackReviewPromptShown(attempt: attempt)
            // Small delay so any swipe/completion animation finishes first.
            try? await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run { showReviewPrompt = true }
        }
    }

    private func clearAllCards() {
        withAnimation {
            cards.removeAll()
            priorityCardIds.removeAll()
        }
    }

    // MARK: - Priority

    private func syncPriorityOrder() {
        let eligibleIds = Set(cards.filter { !excludedFromPriorityIds.contains($0.id) }.map { $0.id })
        var newOrder = priorityCardIds.filter { eligibleIds.contains($0) }
        let missing = cards
            .filter { eligibleIds.contains($0.id) && !newOrder.contains($0.id) }
            .sorted { $0.timestamp > $1.timestamp }
        newOrder.append(contentsOf: missing.map { $0.id })
        priorityCardIds = newOrder
    }

    private func addToPriorities(_ cardId: UUID) {
        if !priorityCardIds.contains(cardId) && priorityCardIds.count < 3 {
            priorityCardIds.append(cardId)
        }
    }

    // MARK: - Text Transform

    private func transformToAction(_ text: String) -> String {
        let lowercased = text.lowercased()
        for (keyword, action) in actionTransformations {
            if lowercased.contains(keyword) {
                if lowercased.hasPrefix(action.lowercased()) { return text }
                if !action.contains("for") && !action.contains("about") && !action.contains("the") {
                    let words = action.split(separator: " ")
                    if words.count >= 3 || action == "Buy groceries" || action == "Drink more water" {
                        return action
                    }
                }
                return "\(action) \(text)"
            }
        }
        return text
    }

    private func findEmoji(for text: String) -> String? {
        let lowercased = text.lowercased()
        for (keyword, emoji) in emojiMap {
            if lowercased.contains(keyword) { return emoji }
        }
        return nil
    }

    // MARK: - Onboarding

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        Analytics.shared.trackOnboardingCompleted()
        showOnboarding = false
        if !cards.isEmpty {
            // Present after the cover's dismissal animation to avoid a
            // sheet/fullScreenCover presentation conflict.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showRecentSheet = true }
        }
    }

    private func resetOnboarding() {
        withAnimation {
            widgetOnboardingDismissed = false
            captureOnboardingDismissed = false
            priorityCardIds.removeAll()
            excludedFromPriorityIds.removeAll()
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "widgetOnboardingDismissed")
            UserDefaults.standard.removeObject(forKey: "captureOnboardingDismissed")
            UserDefaults.standard.removeObject(forKey: "priorityCardIds")
            UserDefaults.standard.removeObject(forKey: "excludedFromPriorityIds")
        }
        // Replay the flow: close Settings first, then present the cover
        // (two simultaneous presentations from ContentView would conflict).
        showSettings = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showOnboarding = true }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Persistence

    private func saveState() {
        let encoder = JSONEncoder()
        if let cardsData = try? encoder.encode(cards) {
            UserDefaults.standard.set(cardsData, forKey: "cards")
        }
        UserDefaults.standard.set(priorityCardIds.map { $0.uuidString }, forKey: "priorityCardIds")
        UserDefaults.standard.set(widgetOnboardingDismissed, forKey: "widgetOnboardingDismissed")
        UserDefaults.standard.set(captureOnboardingDismissed, forKey: "captureOnboardingDismissed")
        UserDefaults.standard.set(excludedFromPriorityIds.map { $0.uuidString }, forKey: "excludedFromPriorityIds")

        SharedCardManager.shared.saveCurrentCard(widgetPriorityCards.first)
        SharedCardManager.shared.savePriorityCards(widgetPriorityCards)
        SharedCardManager.shared.saveAllCards(cards)

        #if canImport(WidgetKit)
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
        #endif

        rescheduleReminders()
    }

    private func rescheduleReminders() {
        NotificationManager.shared.schedulePriorityUpdate(cards: widgetPriorityCards)
        NotificationManager.shared.scheduleDailyDigest(cards: widgetPriorityCards)
    }

    private func loadState() {
        let decoder = JSONDecoder()
        if let cardsData = UserDefaults.standard.data(forKey: "cards"),
           let loadedCards = try? decoder.decode([Card].self, from: cardsData) {
            cards = loadedCards
        }
        if let priorityStrings = UserDefaults.standard.array(forKey: "priorityCardIds") as? [String] {
            priorityCardIds = priorityStrings.compactMap { UUID(uuidString: $0) }
        }
        widgetOnboardingDismissed = UserDefaults.standard.bool(forKey: "widgetOnboardingDismissed")
        captureOnboardingDismissed = UserDefaults.standard.bool(forKey: "captureOnboardingDismissed")
        if let excludedStrings = UserDefaults.standard.array(forKey: "excludedFromPriorityIds") as? [String] {
            excludedFromPriorityIds = excludedStrings.compactMap { UUID(uuidString: $0) }
        }
        syncWidgetCompletions()
    }

    private func syncWidgetCompletions() {
        let completedCards = SharedCardManager.shared.loadCompletedCards()
        guard !completedCards.isEmpty else { return }
        let completedIDs = Set(completedCards.map { $0.id })
        let beforeCount = cards.count
        cards.removeAll { completedIDs.contains($0.id) }
        priorityCardIds.removeAll { completedIDs.contains($0) }
        if cards.count != beforeCount {
            SharedCardManager.shared.clearCompletedCards()
        }
    }
}

// MARK: - Priority Picker View

struct PriorityPickerView: View {
    let cards: [Card]
    let onSelect: (Card) -> Void
    let onCaptureText: () -> Void
    let onCaptureVoice: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("audioInputEnabled") private var audioInputEnabled: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    VStack(spacing: 32) {
                        Spacer()

                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(Material.Icon.muted)

                        VStack(spacing: 12) {
                            Text("No other captures")
                                .font(AppFont.icon).fontWeight(.semibold)
                                .foregroundColor(Material.Text.primary)
                            Text("Capture something new to set as a priority")
                                .font(AppFont.body)
                                .foregroundColor(Material.Text.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        HStack(spacing: 16) {
                            if audioInputEnabled {
                                Button {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onCaptureVoice() }
                                } label: {
                                    Label("Voice", systemImage: "mic.fill")
                                }
                                .buttonStyle(.filled)
                            }
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onCaptureText() }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                    Text("Note")
                                }
                            }
                            .primaryButtonStyle()
                        }

                        Spacer()
                    }
                } else {
                    List {
                        ForEach(cards) { card in
                            Button { onSelect(card) } label: {
                                HStack(spacing: 16) {
                                    if let emoji = card.emoji {
                                        Text(emoji).font(.system(size: 32))
                                    }
                                    Text(card.simplifiedText)
                                        .font(AppFont.body).fontWeight(.medium)
                                        .foregroundColor(Material.Text.primary)
                                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Turn on a priority")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

// Recent sheet panel background. On iOS 26 we deliberately apply NO override so the
// sheet keeps its native Liquid Glass material and the cloud-shader backdrop refracts
// through (Files-style). Overriding with a Material (even .ultraThinMaterial) defeats
// that glass and renders a flat, near-opaque panel. Pre-iOS-26 uses the opaque surface.
private struct RecentSheetBackground: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            content.presentationBackground(Material.Surface.secondary)
        }
    }
}
