import SwiftUI
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif


struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
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
    /// Long-press–then–drag priority reorder (no list edit mode).
    @State private var priorityReorderLiftedId: UUID?
    @State private var priorityReorderTranslation: CGSize = .zero
    /// After a long-press reorder lifts a card, ignore the finger-up “tap” so the detail sheet does not open.
    @State private var suppressNextPrioritySelectionId: UUID?

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
                Material.Surface.backdrop.ignoresSafeArea()

                if cards.isEmpty {
                    emptyState
                } else {
                    cardList
                }
            }
            .simultaneousGesture(recentSheetDragGesture)
            .navigationTitle("Miranda")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "tortoise.fill")
                            .font(AppFont.icon).fontWeight(.regular)
                            .foregroundColor(Material.Icon.primary)
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
            noteDetail(for: card)
        }
        .sheet(isPresented: $showCompleteTortoise, onDismiss: {
            showCompleteTortoise = false
        }) {
            completionSheet
        }
        .sheet(isPresented: $showAnalytics) {
            AnalyticsDebugView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                onShowAnalytics: {
                    showSettings = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showAnalytics = true }
                },
                onDeleteAll: { clearAllCards() },
                onResetOnboarding: { resetOnboarding() },
                currentPriorityCard: priorityCards.first,
                lastCapture: cards.max(by: { $0.timestamp < $1.timestamp }),
                hasCaptures: !cards.isEmpty
            )
        }
        .sheet(isPresented: $showWidgetInstructions) {
            NavigationStack {
                WidgetInstructionsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showWidgetInstructions = false }
                        }
                    }
            }
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
                    if !cards.isEmpty { showRecentSheet = true }
                } else if dy > 0 {
                    showRecentSheet = false
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
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
                .font(AppFont.body)
                .foregroundColor(Material.Text.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 25)
                .padding(.vertical, 50)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(card.simplifiedText)
        .accessibilityIdentifier("priority-note-\(card.id.uuidString)")
        .accessibilityHint(allowDragReorder ? "Long press, then drag up or down to reorder" : "")
        .background(
            Group {
                if allowDragReorder {
                    LongPressDragGesture(
                        cardId: card.id,
                        cardIndex: index,
                        liftedId: $priorityReorderLiftedId,
                        translation: $priorityReorderTranslation,
                        onStart: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            suppressNextPrioritySelectionId = card.id
                            priorityReorderLiftedId = card.id
                        },
                        onEnd: { dy in
                            let id = card.id
                            if priorityReorderLiftedId == id {
                                commitPriorityReorderFromDrag(
                                    sourceIndex: index,
                                    translation: CGSize(width: 0, height: dy)
                                )
                            }
                            priorityReorderLiftedId = nil
                            priorityReorderTranslation = .zero
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                if suppressNextPrioritySelectionId == id {
                                    suppressNextPrioritySelectionId = nil
                                }
                            }
                        }
                    )
                }
            }
        )
        .cardSurface(Material.Card.gradient(for: index))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
        .scaleEffect(liftedHere ? 1.03 : 1)
        .opacity(reorderActiveElsewhere ? 0.55 : 1)
        .zIndex(liftedHere ? 1 : 0)
        .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.82), value: priorityReorderTranslation)
        .animation(.spring(response: 0.34, dampingFraction: 0.78), value: liftedHere)
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
            } label: {
                Label("Priority", systemImage: "lightbulb.fill")
            }
            .tint(.yellow)
        }
    }

    // MARK: - Note Detail

    @ViewBuilder
    private func noteDetail(for card: Card) -> some View {
        let isPriority = autoPriorityCardIds.contains(card.id)
        NavigationStack {
            ScrollView {
                VStack(spacing: 50) {
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
                .frame(maxWidth: .infinity)
            }
            .background(Material.Surface.tertiary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { selectedCard = nil }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Divider()

                    Button {
                        selectedCard = nil
                        if isPriority { completePriorityCard(card) }
                        else { completeCard(card) }
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
                            saveState()
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
                            saveState()
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
        .onAppear { Analytics.shared.trackCardViewed() }
    }

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

        let eligibleForPriority = sortedCards.filter { !excludedFromPriorityIds.contains($0.id) }
        let widgetPriorityCards = Array(eligibleForPriority.prefix(3))
        SharedCardManager.shared.saveCurrentCard(widgetPriorityCards.first)
        SharedCardManager.shared.savePriorityCards(widgetPriorityCards)
        SharedCardManager.shared.saveAllCards(cards)

        #if canImport(WidgetKit)
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
        #endif

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

// MARK: - Create Card Modal

struct CreateCardModal: View {
    @Binding var text: String
    let startWithDictation: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFocused: Bool

    let allCommonHints = [
        "Flush the toilet 🚽", "Dance for 10 seconds 💃", "Don't forget your keys 🔑",
        "Prepare slides for presentation 📊", "Buy an umbrella ☂️", "Charge your phone 🔋",
        "Take your medicine 💊", "Water the plants 🪴", "Call mom 📞", "Pay the bills 💳",
        "Check the mail 📬", "Lock the door 🔐", "Turn off the lights 💡",
        "Take out the trash 🗑️", "Feed the pet 🐕", "Bring reusable bags 🛍️",
        "Set an alarm ⏰", "Backup your files 💾", "Reply to that email 📧",
        "Schedule dentist appointment 🦷"
    ]

    @State private var commonHints: [String] = []

    let randomSuggestions = [
        "Compliment your coffee mug ☕️", "Name all the colors you can see 🌈",
        "Count backwards from 10 in Spanish 🇪🇸", "Do a silly walk to the kitchen 🚶",
        "Smell a lemon 🍋", "High-five yourself 🙌", "Whisper 'good job' to your plant 🪴",
        "Touch something blue 💙", "Make a weird face in the mirror 😜",
        "Pet an imaginary dog 🐕", "Sing one word of your favorite song 🎵",
        "Stretch like a cat 🐱", "Blink 20 times really fast 👁️",
        "Say 'potato' in 3 different accents 🥔", "Spin around three times slowly 🌀",
        "Name your shoes out loud 👟", "Wave at something random 👋",
        "Hum the Jeopardy theme 🎶", "Balance on one foot for 10 seconds 🦩",
        "Make up a word and use it in a sentence 💭", "Count how many pens you have ✍️",
        "Tap your nose 7 times 👃", "Say the alphabet backwards from G 🔤",
        "Wiggle your toes 🦶", "Name three things you're grateful for 🙏",
        "Do 5 jumping jacks 🤸", "Drink a glass of water 💧", "Take 3 deep breaths 🫁",
        "Look out the window for 30 seconds 🪟",
        "Write your name with your non-dominant hand ✏️", "Snap your fingers 10 times 🫰",
        "Touch your elbows together 💪", "Make a bird sound 🐦",
        "Pretend you're a robot for 15 seconds 🤖", "Organize one thing on your desk 📎"
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
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
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
                isTextFocused = true
                commonHints = Array(allCommonHints.shuffled().prefix(3))
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
