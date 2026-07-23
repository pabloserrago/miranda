import SwiftUI
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

private struct ScrollAnchorKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var cards: [Card] = []
    @State private var priorityCardIds: [UUID] = []
    @State private var selectedCard: Card? = nil
    @State private var showAnalytics: Bool = false
    @State private var showSettings: Bool = false
    @State private var showCreateModal: Bool = false
    @State private var newCardText: String = ""
    @State private var startWithDictation: Bool = false
    @State private var showDoNowDialog: Bool = false
    @State private var pendingCard: Card? = nil
    @State private var showPriorityPicker: Bool = false
    @State private var showCompleteTortoise: Bool = false
    @State private var showWidgetInstructions: Bool = false
    @State private var searchText: String = ""
    @State private var widgetOnboardingDismissed: Bool = false
    @State private var captureOnboardingDismissed: Bool = false
    @State private var lockScreenOnboardingDismissed: Bool = false
    @State private var excludedFromPriorityIds: [UUID] = []
    @State private var showRecentSheet: Bool = false
    @State private var showReviewPrompt: Bool = false
    /// Long-press–then–drag priority reorder (no list edit mode).
    @State private var priorityReorderLiftedId: UUID?
    @State private var priorityReorderLiftedIndex: Int?
    @State private var priorityReorderTranslation: CGSize = .zero
    /// Finger drift accumulated during the 0.45 s hold before the long press fires.
    /// Subtracted from all subsequent translations so the card starts at offset 0.
    @State private var priorityReorderDragBaseline: CGFloat = 0
    /// Set while a card is being held before the long-press threshold fires (drives the charging scale).
    @State private var priorityReorderPressingId: UUID?
    /// After a long-press reorder lifts a card, ignore the finger-up “tap” so the detail sheet does not open.
    @State private var suppressNextPrioritySelectionId: UUID?

    @State private var scrollOffset: CGFloat = 0
    @State private var scrollAnchorY: CGFloat?

    /// Minimum list content-offset delta (pt) before toggling Recent sheet visibility.
    private let recentSheetScrollThreshold: CGFloat = 12

    @AppStorage("audioInputEnabled") private var audioInputEnabled: Bool = false
    @AppStorage("actionTransformEnabled") private var actionTransformEnabled: Bool = false
    @AppStorage("completionAnimationEnabled") private var completionAnimationEnabled: Bool = true
    init() {
        #if DEBUG
        if ContentView.isUITestLaunch {
            _cards = State(initialValue: ContentView.uiTestSeedCards)
            _widgetOnboardingDismissed = State(initialValue: true)
            _captureOnboardingDismissed = State(initialValue: true)
            _lockScreenOnboardingDismissed = State(initialValue: true)
            _showRecentSheet = State(initialValue: false)
        }
        #endif
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
                    scrollOffset: scrollOffset
                ).ignoresSafeArea()

                if cards.isEmpty {
                    emptyState
                } else {
                    cardList
                }
            }
            .simultaneousGesture(recentSheetDragGesture)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Text("🐢")
                            .font(.system(size: 24.2))
                    }
                }
            }
        }
        .tint(Material.Text.accent)
        .onAppear {
            #if DEBUG
            if ContentView.isUITestLaunch {
                Analytics.shared.trackAppOpened()
                return
            }
            #endif
            loadState()
            Analytics.shared.trackAppOpened()
            showRecentSheet = !cards.isEmpty
        }
        .onChange(of: cards) { _, _ in
            saveState()
        }
        .onChange(of: cards.isEmpty) { wasEmpty, isEmpty in
            if isEmpty {
                showRecentSheet = false
            } else if wasEmpty {
                showRecentSheet = true
            }
        }
        .onChange(of: cards.count) { oldCount, newCount in
            if newCount > oldCount, !cards.isEmpty {
                showRecentSheet = true
            }
        }
        .onChange(of: priorityCardIds) { _, _ in saveState() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                syncWidgetCompletions()
                NotificationManager.shared.syncAuthorizationStatus()
            }
        }
        .onOpenURL { url in
            guard url.scheme == "miranda" else { return }
            if url.host == "capture" {
                newCardText = ""
                startWithDictation = false
                showCreateModal = true
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
                selectedCard: $selectedCard,
                cards: $cards,
                excludedFromPriorityIds: $excludedFromPriorityIds,
                autoPriorityCardIds: autoPriorityCardIds,
                onSave: saveState,
                onComplete: completeCard,
                onCompletePriority: completePriorityCard
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
        .sheet(isPresented: $showCreateModal) {
            CreateCardModal(
                text: $newCardText,
                startWithDictation: startWithDictation,
                onSave: { createCard() },
                onCancel: {
                    newCardText = ""
                    showCreateModal = false
                    startWithDictation = false
                }
            )
            .presentationBackground(Material.Surface.secondary)
        }
        .sheet(isPresented: $showPriorityPicker) {
            PriorityPickerView(
                cards: cards.sorted { $0.timestamp > $1.timestamp }
                    .filter { !priorityCardIds.contains($0.id) },
                onSelect: { card in
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    addToPriorities(card.id)
                    saveState()
                    showPriorityPicker = false
                },
                onCaptureText: {
                    newCardText = ""
                    startWithDictation = false
                    showCreateModal = true
                },
                onCaptureVoice: {
                    newCardText = ""
                    startWithDictation = true
                    showCreateModal = true
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
                newCardText = ""
                startWithDictation = false
                showCreateModal = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Note")
                }
            }
            .buttonStyle(.solid)

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
            Color.clear
                .frame(height: 0)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .background(GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollAnchorKey.self,
                        value: geo.frame(in: .global).minY
                    )
                })

            if !widgetOnboardingDismissed && !autoPriorityCards.isEmpty && autoPriorityCards.count < 3 {
                Section {
                    widgetOnboardingRow
                }
            }

            if widgetOnboardingDismissed && !lockScreenOnboardingDismissed && !autoPriorityCards.isEmpty {
                Section {
                    lockScreenOnboardingRow
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
        .onPreferenceChange(ScrollAnchorKey.self) { y in
            if scrollAnchorY == nil { scrollAnchorY = y }
            scrollOffset = max(0, (scrollAnchorY ?? y) - y)
        }
        // Disable list scrolling while a card is lifted so the DragGesture
        // can track vertical movement without competing with the scroll view.
        .scrollDisabled(priorityReorderPressingId != nil || priorityReorderLiftedId != nil)
        // DragGesture lives at the List level (above individual cells) so it:
        //   1. Always receives ongoing touches that started on any row, and
        //   2. Never competes with cell-level swipe action pan recognizers.
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    guard priorityReorderLiftedId != nil else { return }
                    if priorityReorderTranslation == .zero && priorityReorderDragBaseline == 0 {
                        // First update after lift: zero-out any drift accumulated during the hold.
                        priorityReorderDragBaseline = value.translation.height
                    }
                    let calibrated = value.translation.height - priorityReorderDragBaseline
                    priorityReorderTranslation = CGSize(width: 0, height: calibrated)
                }
                .onEnded { value in
                    guard let idx = priorityReorderLiftedIndex else { return }
                    let capturedId = priorityReorderLiftedId
                    let calibrated = value.translation.height - priorityReorderDragBaseline
                    let capturedTranslation = CGSize(width: 0, height: calibrated)

                    // Phase 1: animate card back to neutral.
                    priorityReorderPressingId = nil
                    priorityReorderLiftedId = nil
                    priorityReorderLiftedIndex = nil
                    priorityReorderTranslation = .zero
                    priorityReorderDragBaseline = 0

                    // Phase 2: commit list reorder after the return spring settles.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        commitPriorityReorderFromDrag(sourceIndex: idx, translation: capturedTranslation)
                    }
                    if let id = capturedId {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            if suppressNextPrioritySelectionId == id {
                                suppressNextPrioritySelectionId = nil
                            }
                        }
                    }
                }
        )
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

    @ViewBuilder
    private var lockScreenOnboardingRow: some View {
        Button { showWidgetInstructions = true } label: {
            VStack(alignment: .leading) {
                Group {
                    Text("Miranda can show your priorities on your Lock Screen. ")
                    + Text("Add it once, see them always.").bold()
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
                withAnimation { lockScreenOnboardingDismissed = true }
                saveState()
            } label: {
                Label("Dismiss", systemImage: "xmark")
            }
        }
    }

    // MARK: - Recent Sheet

    @ViewBuilder
    private var recentSheet: some View {
        NavigationStack {
            List {
                ForEach(filteredNonPriorityCards) { card in
                    recentRow(card)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .overlay {
                if filteredNonPriorityCards.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundColor(Material.Icon.muted)
                        Text(searchText.isEmpty ? "All caught up" : "No results")
                            .font(AppFont.body)
                            .foregroundColor(Material.Text.secondary)
                    }
                }
            }
            .background(Material.Surface.primary)
            .navigationTitle("Recent")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Find...")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if audioInputEnabled {
                        Button {
                            newCardText = ""
                            startWithDictation = true
                            showCreateModal = true
                        } label: {
                            Image(systemName: "mic.fill")
                        }
                    }
                    Button {
                        newCardText = ""
                        startWithDictation = false
                        showCreateModal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.25), .medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .presentationBackground(Material.Surface.secondary)
        .interactiveDismissDisabled()
        .presentationDragIndicator(.visible)
    }

    // MARK: - Priority Row (gradient card)

    @ViewBuilder
    private func priorityRow(_ card: Card, index: Int = 0, allowDragReorder: Bool = false) -> some View {
        let liftedHere = priorityReorderLiftedId == card.id
        let pressingHere = priorityReorderPressingId == card.id
        let reorderActiveElsewhere = allowDragReorder && priorityReorderLiftedId != nil && priorityReorderLiftedId != card.id

        Button {
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
                .lineLimit(4)
                .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(card.simplifiedText)
        .accessibilityIdentifier("priority-note-\(card.id.uuidString)")
        .accessibilityHint(allowDragReorder ? "Long press, then drag up or down to reorder" : "")
        .onLongPressGesture(
            minimumDuration: 0.45,
            maximumDistance: 50,
            perform: {
                guard allowDragReorder else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                suppressNextPrioritySelectionId = card.id
                priorityReorderLiftedId = card.id
                priorityReorderLiftedIndex = index
            },
            onPressingChanged: { isPressing in
                guard allowDragReorder else { return }
                priorityReorderPressingId = isPressing ? card.id : nil
            }
        )
        .cardSurface(
            Material.Card.colors(for: index),
            borderColor: Material.Card.border,
            borderWidth: Material.Card.borderWidth
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { removePriorityCard(card) } label: {
                Label("Remove", systemImage: "lightbulb.slash")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { deleteCard(card) } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            Button { completePriorityCard(card) } label: {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(.green)
        }
        .offset(y: liftedHere ? priorityReorderTranslation.height : 0)
        .scaleEffect(liftedHere ? 1.06 : (pressingHere ? 1.03 : 1.0))
        .opacity(reorderActiveElsewhere ? 0.55 : 1)
        .zIndex(liftedHere ? 1 : 0)
        // During drag: interactive spring tracks the finger.
        // On drop: slower, heavily-damped spring eases the card back without bounce.
        .animation(
            liftedHere
                ? .interactiveSpring(response: 0.28, dampingFraction: 0.82)
                : .spring(response: 0.45, dampingFraction: 0.95),
            value: priorityReorderTranslation
        )
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: pressingHere)
        .animation(.spring(response: 0.25, dampingFraction: 0.92), value: liftedHere)
        .shadow(
            color: liftedHere ? Material.Elevation.shadow.opacity(0.32) : .clear,
            radius: liftedHere ? 28 : 0,
            x: 0,
            y: liftedHere ? 18 : 0
        )
    }

    // MARK: - Recent Row (subtle card)

    @ViewBuilder
    private func recentRow(_ card: Card) -> some View {
        Button { selectedCard = card } label: {
            Text(card.simplifiedText)
                .font(AppFont.body)
                .foregroundColor(Material.Text.primary)
                .lineLimit(2)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recent-note-\(card.id.uuidString)")
        .cardSurface([Material.Control.fillSecondary], shadow: false)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { deleteCard(card) } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            Button { completeCard(card) } label: {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(.green)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                withAnimation { excludedFromPriorityIds.removeAll { $0 == card.id } }
                saveState()
                maybePromptReview()
            } label: {
                Label("Priority", systemImage: "lightbulb.fill")
            }
            .tint(.yellow)
        }
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
        if priorityCardIds.count < 3 && !cards.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showPriorityPicker = true
            }
        }
    }

    // MARK: - Reorder

    /// Approximate row stride (card + list insets) for mapping drag distance to index delta.
    private let priorityReorderRowStride: CGFloat = 125

    private func movePriorityFromIndex(from: Int, to: Int) {
        guard from != to else { return }
        let count = autoPriorityCards.count
        guard from >= 0, to >= 0, from < count, to < count else { return }
        syncPriorityOrder()
        var ids = autoPriorityCards.map(\.id)
        let id = ids.remove(at: from)
        ids.insert(id, at: to)
        priorityCardIds = ids
        saveState()
    }

    private func commitPriorityReorderFromDrag(sourceIndex: Int, translation: CGSize) {
        let count = autoPriorityCards.count
        guard count > 1 else { return }
        let delta = Int(round(translation.height / priorityReorderRowStride))
        var target = sourceIndex + delta
        target = min(max(0, target), count - 1)
        guard target != sourceIndex else { return }
        movePriorityFromIndex(from: sourceIndex, to: target)
    }

    // MARK: - Card Actions

    private func createCard() {
        guard !newCardText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let originalText = newCardText
        let actionText = actionTransformEnabled ? transformToAction(originalText) : originalText
        let newCard = Card(
            originalText: originalText,
            simplifiedText: actionText,
            emoji: nil,
            timestamp: Date()
        )
        cards.append(newCard)
        let currentPriorityCount = cards.filter { !excludedFromPriorityIds.contains($0.id) }.count
        if currentPriorityCount > 3 { excludedFromPriorityIds.append(newCard.id) }
        Analytics.shared.trackCardCreated(hasEmoji: false)
        newCardText = ""
        showCreateModal = false
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
        if completionAnimationEnabled {
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

    private func resetOnboarding() {
        withAnimation {
            widgetOnboardingDismissed = false
            captureOnboardingDismissed = false
            lockScreenOnboardingDismissed = false
            priorityCardIds.removeAll()
            excludedFromPriorityIds.removeAll()
            UserDefaults.standard.removeObject(forKey: "widgetOnboardingDismissed")
            UserDefaults.standard.removeObject(forKey: "captureOnboardingDismissed")
            UserDefaults.standard.removeObject(forKey: "lockScreenOnboardingDismissed")
            UserDefaults.standard.removeObject(forKey: "priorityCardIds")
            UserDefaults.standard.removeObject(forKey: "excludedFromPriorityIds")
        }
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
        UserDefaults.standard.set(lockScreenOnboardingDismissed, forKey: "lockScreenOnboardingDismissed")
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
        lockScreenOnboardingDismissed = UserDefaults.standard.bool(forKey: "lockScreenOnboardingDismissed")
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

// MARK: - Note Detail View

struct NoteDetailView: View {
    let card: Card
    @Binding var selectedCard: Card?
    @Binding var cards: [Card]
    @Binding var excludedFromPriorityIds: [UUID]
    let autoPriorityCardIds: Set<UUID>
    let onSave: () -> Void
    let onComplete: (Card) -> Void
    let onCompletePriority: (Card) -> Void

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isTextFocused: Bool

    private var isPriority: Bool {
        autoPriorityCardIds.contains(card.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 50) {
                    if isEditing {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $editText)
                                .focused($isTextFocused)
                                .scrollContentBackground(.hidden)
                                .font(AppFont.body)
                                .padding(8)
                            if editText.isEmpty {
                                Text("What do you want to capture?")
                                    .font(AppFont.body)
                                    .foregroundColor(Material.Text.secondary)
                                    .padding(.top, 16)
                                    .padding(.leading, 13)
                                    .allowsHitTesting(false)
                            }
                        }
                        .frame(minHeight: 120)
                        .background(Material.Surface.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: Material.Shape.input))
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    } else {
                        Spacer(minLength: 80)
                        if let emoji = card.emoji {
                            Text(emoji).font(.system(size: 120))
                        }
                        Text(card.simplifiedText)
                            .font(AppFont.title)
                            .foregroundColor(Material.Text.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer(minLength: 120)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .background(Material.Surface.tertiary)
            .navigationTitle(isEditing ? "Edit Note" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            isEditing = false
                            editText = ""
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: saveEdit) {
                            Image(systemName: "checkmark")
                        }
                        .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { selectedCard = nil }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") {
                            editText = card.simplifiedText
                            isEditing = true
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !isEditing {
                    VStack(spacing: 12) {
                        Divider()

                        Button {
                            selectedCard = nil
                            if isPriority { onCompletePriority(card) }
                            else { onComplete(card) }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark").fontWeight(.heavy)
                                Text("Complete")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.solid)
                        .padding(.horizontal, 20)

                        if !isPriority {
                            Button {
                                excludedFromPriorityIds.removeAll { $0 == card.id }
                                onSave()
                                selectedCard = nil
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.fill").fontWeight(.heavy)
                                    Text("Turn this on")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.filled)
                            .padding(.horizontal, 20)
                        } else {
                            Button {
                                if !excludedFromPriorityIds.contains(card.id) {
                                    excludedFromPriorityIds.append(card.id)
                                }
                                onSave()
                                selectedCard = nil
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.slash.fill").fontWeight(.heavy)
                                    Text("Turn this off")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.filled)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .background(Material.Surface.tertiary)
                }
            }
        }
        .onChange(of: isEditing) { _, newValue in
            if newValue { isTextFocused = true }
        }
        .onAppear { Analytics.shared.trackCardViewed() }
    }

    private func saveEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx] = Card(
                id: card.id,
                originalText: trimmed,
                simplifiedText: trimmed,
                emoji: card.emoji,
                timestamp: card.timestamp
            )
        }
        onSave()
        isEditing = false
    }
}

// MARK: - Create Card Modal

struct CreateCardModal: View {
    @Binding var text: String
    let startWithDictation: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFocused: Bool
    @AppStorage("audioInputEnabled") private var audioInputEnabled: Bool = false
    @StateObject private var dictation = SpeechDictationManager()
    /// Text present when dictation began, so live transcript extends it.
    @State private var baseText: String = ""

    let allCommonHints = [
        String(localized: "Flush the toilet 🚽",                   comment: "Common hint shown in create note screen"),
        String(localized: "Dance for 10 seconds 💃",               comment: "Common hint shown in create note screen"),
        String(localized: "Don't forget your keys 🔑",             comment: "Common hint shown in create note screen"),
        String(localized: "Prepare slides for presentation 📊",    comment: "Common hint shown in create note screen"),
        String(localized: "Buy an umbrella ☂️",                    comment: "Common hint shown in create note screen"),
        String(localized: "Charge your phone 🔋",                  comment: "Common hint shown in create note screen"),
        String(localized: "Take your medicine 💊",                 comment: "Common hint shown in create note screen"),
        String(localized: "Water the plants 🪴",                   comment: "Common hint shown in create note screen"),
        String(localized: "Call mom 📞",                           comment: "Common hint shown in create note screen"),
        String(localized: "Pay the bills 💳",                      comment: "Common hint shown in create note screen"),
        String(localized: "Check the mail 📬",                     comment: "Common hint shown in create note screen"),
        String(localized: "Lock the door 🔐",                      comment: "Common hint shown in create note screen"),
        String(localized: "Turn off the lights 💡",                comment: "Common hint shown in create note screen"),
        String(localized: "Take out the trash 🗑️",                 comment: "Common hint shown in create note screen"),
        String(localized: "Feed the pet 🐕",                       comment: "Common hint shown in create note screen"),
        String(localized: "Bring reusable bags 🛍️",                comment: "Common hint shown in create note screen"),
        String(localized: "Set an alarm ⏰",                        comment: "Common hint shown in create note screen"),
        String(localized: "Backup your files 💾",                  comment: "Common hint shown in create note screen"),
        String(localized: "Reply to that email 📧",                comment: "Common hint shown in create note screen"),
        String(localized: "Schedule dentist appointment 🦷",       comment: "Common hint shown in create note screen"),
    ]

    @State private var commonHints: [String] = []

    let randomSuggestions = [
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

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .focused($isTextFocused)
                        .scrollContentBackground(.hidden)
                        .font(AppFont.body)
                        .padding(8)

                    if text.isEmpty {
                        Text("What do you want to capture?")
                            .font(AppFont.body)
                            .foregroundColor(Material.Text.secondary)
                            .padding(.top, 16)
                            .padding(.leading, 13)
                            .allowsHitTesting(false)
                    }
                }
                .frame(minHeight: 120)
                .background(Material.Surface.secondary)
                .clipShape(RoundedRectangle(cornerRadius: Material.Shape.input))

                if audioInputEnabled {
                    HStack(spacing: 12) {
                        Button {
                            dictation.toggle()
                        } label: {
                            Label(
                                dictation.isRecording ? "Stop" : "Dictate",
                                systemImage: dictation.isRecording ? "stop.fill" : "mic.fill"
                            )
                        }
                        .buttonStyle(.filled)

                        if dictation.isRecording {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.accent)
                                    .symbolEffect(.variableColor.iterative, options: .repeating)
                                Text("Listening…")
                                    .font(AppFont.caption)
                                    .foregroundColor(Material.Text.secondary)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(commonHints, id: \.self) { hint in
                        ListSuggestion(text: hint) { text = hint }
                    }
                }

                Spacer()
            }
            .padding()
            .background(Material.Surface.tertiary)
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dictation.stop()
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dictation.stop()
                        onSave()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .keyboard) {
                    Button {
                        text = randomSuggestions.randomElement() ?? ""
                    } label: {
                        Label("Generate", systemImage: "dice.fill")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .onAppear {
                commonHints = Array(allCommonHints.shuffled().prefix(3))
                baseText = text
                if startWithDictation && audioInputEnabled {
                    dictation.requestAuthorizationAndStart()
                } else {
                    isTextFocused = true
                }
            }
            .onChange(of: dictation.transcript) { _, newValue in
                text = SpeechDictationManager.compose(base: baseText, transcript: newValue)
            }
            .onChange(of: dictation.permissionDenied) { _, denied in
                if denied { isTextFocused = true }
            }
            .onDisappear {
                dictation.stop()
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
                            .buttonStyle(.solid)
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
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "lightbulb")
                                        .foregroundColor(Material.Text.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Set Priority")
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
