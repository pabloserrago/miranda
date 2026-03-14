import SwiftUI
import UniformTypeIdentifiers
#if canImport(WidgetKit)
import WidgetKit
#endif

// Helper to force keyboard appearance
struct KeyboardTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 18)
        textView.backgroundColor = AppColor.Surface.secondaryUIColor
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.text = text
        context.coordinator.placeholderLabel.text = placeholder
        textView.addSubview(context.coordinator.placeholderLabel)
        NSLayoutConstraint.activate([
            context.coordinator.placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 16),
            context.coordinator.placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 21)
        ])
        // Force keyboard to appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            textView.becomeFirstResponder()
        }
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
        context.coordinator.placeholderLabel.isHidden = !text.isEmpty
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let parent: KeyboardTextField
        let placeholderLabel = UILabel()
        
        init(_ parent: KeyboardTextField) {
            self.parent = parent
            super.init()
            placeholderLabel.text = parent.placeholder
            placeholderLabel.textColor = .placeholderText
            placeholderLabel.font = .systemFont(ofSize: 18)
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var cards: [Card] = []
    @State private var priorityCardIds: [UUID] = [] // Up to 3 priorities
    @State private var showOneMust: Bool = false
    @State private var selectedCard: Card? = nil
    @State private var showCompletionAnimation: Bool = false
    @State private var showAnalytics: Bool = false
    @State private var showSettings: Bool = false
    @State private var showCreateModal: Bool = false
    @State private var newCardText: String = ""
    @State private var isNewCard: Bool = false
    @State private var showAllCards: Bool = false
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
    @FocusState private var isInputFocused: Bool
    @FocusState private var isSearchFocused: Bool
    @State private var drawerState: DrawerState = .small
    @GestureState private var drawerDragOffset: CGFloat = 0
    @State private var draggedCard: Card? = nil
    @State private var draggedCardOffset: CGSize = .zero
    
    @AppStorage("audioInputEnabled") private var audioInputEnabled: Bool = false
    @AppStorage("actionTransformEnabled") private var actionTransformEnabled: Bool = false
    
    private let maxVisibleCards = 6
    
    enum DrawerState {
        case small   // 20%
        case medium  // 50%
        case large   // 100%
        
        func height(screenHeight: CGFloat) -> CGFloat {
            switch self {
            case .small:
                return screenHeight * 0.20
            case .medium:
                return screenHeight * 0.50
            case .large:
                return screenHeight * 1.0
            }
        }
    }
    
    // Computed property to sort cards with priorities first (in order), then by date (newest first)
    private var sortedCards: [Card] {
        cards.sorted { card1, card2 in
            let index1 = priorityCardIds.firstIndex(of: card1.id)
            let index2 = priorityCardIds.firstIndex(of: card2.id)
            
            // Both are priorities - sort by priority order
            if let idx1 = index1, let idx2 = index2 {
                return idx1 < idx2
            }
            
            // card1 is priority, card2 is not
            if index1 != nil { return true }
            
            // card2 is priority, card1 is not
            if index2 != nil { return false }
            
            // Neither are priorities - sort by timestamp (newest first)
            return card1.timestamp > card2.timestamp
        }
    }
    
    // Get priority cards in order
    private var priorityCards: [Card] {
        priorityCardIds.compactMap { id in
            cards.first { $0.id == id }
        }
    }
    
    // Get current auto-priority card IDs (first 3 eligible cards)
    // All cards that are eligible for priority (not excluded)
    private var autoPriorityCardIds: Set<UUID> {
        let eligibleForPriority: [Card] = sortedCards.filter { !excludedFromPriorityIds.contains($0.id) }
        return Set(eligibleForPriority.map { $0.id })
    }
    
    // Filter cards based on search text (exclude auto-priority cards)
    private var filteredNonPriorityCards: [Card] {
        let nonPriorityCards = sortedCards.filter { !autoPriorityCardIds.contains($0.id) }
        if searchText.isEmpty {
            return nonPriorityCards
        }
        return nonPriorityCards.filter { card in
            card.simplifiedText.localizedCaseInsensitiveContains(searchText) ||
            card.originalText.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private let emojiMap: [String: String] = {
        guard let url = Bundle.main.url(forResource: "EmojiMap", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return map
    }()
    
    private let actionTransformations: [String: String] = {
        guard let url = Bundle.main.url(forResource: "ActionTransformations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return map
    }()
    
    var body: some View {
        ZStack {
            // Tortoise completion animation
            if showCompleteTortoise {
                TortoiseCompletionView()
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
            }
            
            if showOneMust, let currentCard = selectedCard {
                // Full-screen "One Must" card
                let isCurrentlyPriority = autoPriorityCardIds.contains(currentCard.id)
                OneMustCardView(
                    card: currentCard,
                    isNewCard: isNewCard,
                    isPriority: isCurrentlyPriority,
                    onDismiss: {
                        showOneMust = false
                        selectedCard = nil
                        isNewCard = false
                    },
                    onSetPriority: {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        // Remove from exclusion list to make it eligible for auto-priority
                        excludedFromPriorityIds.removeAll { $0 == currentCard.id }
                        saveState()
                    },
                    onRemovePriority: isCurrentlyPriority ? {
                        // Add to exclusion list
                        if !excludedFromPriorityIds.contains(currentCard.id) {
                        withAnimation {
                                excludedFromPriorityIds.append(currentCard.id)
                        }
                        }
                        saveState()
                        showOneMust = false
                        selectedCard = nil
                    } : nil,
                    onComplete: {
                        // Check if it's a priority card for special animation
                        if isCurrentlyPriority {
                            showOneMust = false
                            selectedCard = nil
                            completePriorityCard(currentCard)
                        } else {
                            showOneMust = false
                            selectedCard = nil
                            completeCard(currentCard)
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    Analytics.shared.trackCardViewed()
                }
            } else {
                // Main interface with GeometryReader for drawer
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        // Main content area
                ZStack {
                            AppColor.Surface.primary
                        .ignoresSafeArea()
                    
                        VStack(spacing: 0) {
                                if !cards.isEmpty {
                                    // Auto-prioritize: show cards as priorities when ≤3 cards
                                    // Calculate available height for priorities
                                    let baseDrawerHeight: CGFloat = DrawerState.small.height(screenHeight: geometry.size.height)
                                    let topPadding: CGFloat = 60 // Space for settings icon
                                    let availableHeight: CGFloat = geometry.size.height - baseDrawerHeight - topPadding
                                    
                                    // Get cards to display as priorities (all eligible, no limit)
                                    let eligibleForPriority: [Card] = sortedCards.filter { !excludedFromPriorityIds.contains($0.id) }
                                    let autoPriorityCards: [Card] = Array(eligibleForPriority)
                                    
                                    // Determine if we should show widget onboarding card (when fewer than 3 priorities)
                                    let showWidgetCard: Bool = autoPriorityCards.count < 3 && autoPriorityCards.count > 0 && !widgetOnboardingDismissed
                                    let totalDisplayCount: Int = autoPriorityCards.count + (showWidgetCard ? 1 : 0)
                                    
                                    let fixedCardHeight: CGFloat = 180
                                    let shouldScroll: Bool = autoPriorityCards.count > 3
                                    let calculatedHeight: CGFloat = totalDisplayCount > 0 ? (availableHeight - CGFloat(totalDisplayCount * 8)) / CGFloat(totalDisplayCount) : fixedCardHeight
                                    let cardHeight: CGFloat = shouldScroll ? fixedCardHeight : min(calculatedHeight, fixedCardHeight)
                                    
                                    // Show priority cards and optional widget onboarding
                                    Group {
                                        if shouldScroll {
                                            ScrollView(.vertical, showsIndicators: true) {
                                                VStack(spacing: 8) {
                                        // If no priority cards to show, display Capture button
                                        if autoPriorityCards.isEmpty && !showWidgetCard {
                                            Spacer()
                                            
                                            // Capture button
                                            Button(action: {
                                                newCardText = ""
                                                startWithDictation = false
                                                showCreateModal = true
                                            }) {
                                                HStack(spacing: 12) {
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 20, weight: .bold))
                                                    Text("Note")
                                                        .font(.system(size: 20, weight: .bold))
                                                }
                                                .foregroundColor(AppColor.Text.inverse)
                                                .padding(.horizontal, 32)
                                                .padding(.vertical, 16)
                                                .background(AppColor.Text.primary)
                                                .clipShape(Capsule())
                                            }
                                            
                                            Spacer()
                                        }
                                        
                                        // Priority cards
                                        ForEach(Array(autoPriorityCards.enumerated()), id: \.element.id) { index, priorityCard in
                                        HeroCardView(
                                            card: priorityCard,
                                                    height: cardHeight,
                                            onTap: {
                                                selectedCard = priorityCard
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    showOneMust = true
                                                }
                                            },
                                            onComplete: {
                                                        completePriorityCard(priorityCard)
                                            },
                                                onDelete: {
                                                    deleteCard(priorityCard)
                                            },
                                            onRemovePriority: {
                                                    // Exclude from auto-priority (card stays in drawer)
                                                    if !excludedFromPriorityIds.contains(priorityCard.id) {
                                                withAnimation {
                                                            excludedFromPriorityIds.append(priorityCard.id)
                                                }
                                                    }
                                                    saveState()
                                                    },
                                                    onLongPress: {
                                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                                        generator.impactOccurred()
                                                        syncPriorityOrder()
                                                        draggedCard = priorityCard
                                                    }
                                                )
                                                .padding(.horizontal, 20)
                                                .opacity(draggedCard?.id == priorityCard.id ? 0.6 : 1.0)
                                                .scaleEffect(draggedCard?.id == priorityCard.id ? 1.08 : 1.0)
                                                .zIndex(draggedCard?.id == priorityCard.id ? 100 : 0)
                                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: draggedCard?.id)
                                                .onDrop(of: [UTType.text], delegate: CardDropDelegate(
                                                    destinationIndex: index,
                                                    draggedCard: $draggedCard,
                                                    priorityCardIds: $priorityCardIds,
                                                    cards: autoPriorityCards,
                                                    onReorder: { saveState() }
                                                ))
                                        }
                                        
                                        // Widget onboarding card (when 1-2 cards exist)
                                        if showWidgetCard {
                                            WidgetOnboardingCard(
                                                    height: cardHeight,
                                                priorityCard: autoPriorityCards.first,
                                                onDismiss: {
                                                    withAnimation {
                                                        widgetOnboardingDismissed = true
                                                    }
                                                },
                                                onLearnMore: {
                                                    showWidgetInstructions = true
                                                    }
                                                )
                                                .padding(.horizontal, 20)
                                            }
                                                }
                                                .padding(.bottom, baseDrawerHeight + 60)
                                            }
                                        } else {
                                            VStack(spacing: 8) {
                                                // If no priority cards to show, display Capture button
                                                if autoPriorityCards.isEmpty && !showWidgetCard {
                                                    Spacer()
                                                    Button(action: {
                                                        newCardText = ""
                                                        startWithDictation = false
                                                        showCreateModal = true
                                                    }) {
                                                        HStack(spacing: 12) {
                                                            Image(systemName: "plus")
                                                                .font(.system(size: 20, weight: .bold))
                                                            Text("Note")
                                                                .font(.system(size: 20, weight: .bold))
                                                        }
                                                        .foregroundColor(AppColor.Text.inverse)
                                                        .padding(.horizontal, 32)
                                                        .padding(.vertical, 16)
                                                        .background(AppColor.Text.primary)
                                                        .clipShape(Capsule())
                                                    }
                                                    Spacer()
                                                }
                                                
                                                ForEach(Array(autoPriorityCards.enumerated()), id: \.element.id) { index, priorityCard in
                                                    HeroCardView(
                                                        card: priorityCard,
                                                        height: cardHeight,
                                                        onTap: {
                                                            selectedCard = priorityCard
                                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                                showOneMust = true
                                                            }
                                                        },
                                                        onComplete: { completePriorityCard(priorityCard) },
                                                        onDelete: { deleteCard(priorityCard) },
                                                        onRemovePriority: {
                                                            if !excludedFromPriorityIds.contains(priorityCard.id) {
                                                                withAnimation { excludedFromPriorityIds.append(priorityCard.id) }
                                                            }
                                                            saveState()
                                                        },
                                                        onLongPress: {
                                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                                            generator.impactOccurred()
                                                            syncPriorityOrder()
                                                            draggedCard = priorityCard
                                                        }
                                                    )
                                                    .padding(.horizontal, 20)
                                                    .opacity(draggedCard?.id == priorityCard.id ? 0.6 : 1.0)
                                                    .scaleEffect(draggedCard?.id == priorityCard.id ? 1.08 : 1.0)
                                                    .zIndex(draggedCard?.id == priorityCard.id ? 100 : 0)
                                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: draggedCard?.id)
                                                    .onDrop(of: [UTType.text], delegate: CardDropDelegate(
                                                        destinationIndex: index,
                                                        draggedCard: $draggedCard,
                                                        priorityCardIds: $priorityCardIds,
                                                        cards: autoPriorityCards,
                                                        onReorder: { saveState() }
                                                    ))
                                                }
                                                
                                                if showWidgetCard {
                                                    WidgetOnboardingCard(
                                                        height: cardHeight,
                                                        priorityCard: autoPriorityCards.first,
                                                        onDismiss: { withAnimation { widgetOnboardingDismissed = true } },
                                                        onLearnMore: { showWidgetInstructions = true }
                                                    )
                                                    .padding(.horizontal, 20)
                                                }
                                            }
                                            .frame(maxHeight: availableHeight)
                                        }
                                    }
                                    .padding(.top, 0)
                                    .onTapGesture {
                                        if draggedCard != nil {
                                            withAnimation {
                                                draggedCard = nil
                                            }
                                        }
                                    }
                                } else {
                                    // No cards at all - show onboarding card and capture button
                                    VStack(spacing: 24) {
                                Spacer()
                                        
                                        // Onboarding card (dismissible)
                                        if !captureOnboardingDismissed {
                                            DismissibleOnboardingCard(
                                                onDismiss: {
                                                    withAnimation {
                                                        captureOnboardingDismissed = true
                                                        saveState()
                                                    }
                                                }
                                            )
                                            .frame(maxHeight: 200)
                                            .padding(.horizontal, 20)
                                        }
                                        
                                        // Capture button
                                            Button(action: {
                                                newCardText = ""
                                                startWithDictation = false
                                    showCreateModal = true
                                            }) {
                                                HStack(spacing: 12) {
                                                    Image(systemName: "plus")
                                                    .font(.system(size: 20, weight: .bold))
                                                    Text("Note")
                                                    .font(.system(size: 20, weight: .bold))
                                                }
                                            .foregroundColor(AppColor.Text.inverse)
                                            .padding(.horizontal, 32)
                                            .padding(.vertical, 16)
                                            .background(AppColor.Text.primary)
                                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                                    }
                                }
                                
                                // Space for drawer at bottom (25% by default) - only if we have cards
                                if !cards.isEmpty {
                                    Color.clear
                                        .frame(height: DrawerState.small.height(screenHeight: geometry.size.height))
                                }
                    }
                    
                    // Fixed top bar - transparent with blur
                    VStack(spacing: 0) {
                        // Blur background that fades out
                        HStack {
                            Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "tortoise.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColor.Action.destructiveIcon)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .shadow(color: AppColor.shadowMedium, radius: 8, x: 0, y: 2)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                        }
                        
                        // Recent captures drawer - three-state system (overlays at bottom)
                        // Only show if we have cards
                        if !cards.isEmpty {
                            VStack(spacing: 0) {
                            // Drag handle and header (draggable area)
                            VStack(spacing: 0) {
                                // Drag handle
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(AppColor.dragHandle)
                                    .frame(width: 40, height: 5)
                                    .padding(.top, 12)
                                
                                // Header with search field and action buttons
                                HStack(spacing: 12) {
                                    // Search field with glass material
                                    HStack(spacing: 8) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(AppColor.Text.secondary)
                                        
                                        TextField("Find...", text: $searchText)
                                            .font(.system(size: 17))
                                            .textFieldStyle(.plain)
                                            .focused($isSearchFocused)
                                            .submitLabel(.search)
                                        
                                        if !searchText.isEmpty {
                                            Button(action: {
                                                searchText = ""
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(AppColor.Text.secondary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    
                                        // Audio button (if enabled)
                                        if audioInputEnabled {
                                            Button(action: {
                                                newCardText = ""
                                                startWithDictation = true
                                                showCreateModal = true
                                            }) {
                                                Image(systemName: "mic.fill")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(AppColor.Action.destructiveIcon)
                                                .frame(width: 48, height: 48)
                                                .background(AppColor.overlay)
                                                .clipShape(Circle())
                                            }
                                        }
                                        
                                        // Add button
                                        Button(action: {
                                            newCardText = ""
                                            startWithDictation = false
                                            showCreateModal = true
                                        }) {
                                            Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(AppColor.Action.destructiveIcon)
                                            .frame(width: 48, height: 48)
                                            .background(AppColor.overlay)
                                            .clipShape(Circle())
                                        }
                                    }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 12)
                            }
                            .contentShape(Rectangle())
                            .highPriorityGesture(
                                DragGesture(minimumDistance: 10)
                                    .onEnded { value in
                                        let translation = value.translation.height
                                        let velocity = value.predictedEndTranslation.height
                                        
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                            if velocity > 50 || translation > 30 {
                                                // Swipe down - always go to small (25%)
                                                drawerState = .small
                                            } else if velocity < -50 || translation < -30 {
                                                // Swipe up - go to next state
                                                switch drawerState {
                                                case .small:
                                                    drawerState = .medium  // Go to 50%
                                                case .medium:
                                                    drawerState = .large   // Go to 100%
                                                case .large:
                                                    // Already at max, stay at 100%
                                                    break
                                                }
                                            }
                                        }
                                    }
                            )
                            
                            // Cards list or empty state (exclude priority cards, apply search filter)
                            if filteredNonPriorityCards.isEmpty {
                                // No results
                                VStack(spacing: 8) {
                                    if !searchText.isEmpty {
                                        Text("No results for \"\(searchText)\"")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(AppColor.Text.secondary)
                                    } else {
                                Text("No Recent Notes")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(AppColor.Text.secondary)
                                    
                                    #if DEBUG
                                    Text("Debug: \(cards.count) cards, \(excludedFromPriorityIds.count) excluded, \(autoPriorityCardIds.count) priorities")
                                        .font(.system(size: 10))
                                        .foregroundColor(AppColor.debugText)
                                    #endif
                                    }
                                }
                                    .padding(.vertical, 20)
                                .frame(maxWidth: .infinity, alignment: .top)
                            } else {
                                ScrollView {
                                    VStack(spacing: 12) {
                                        ForEach(Array(filteredNonPriorityCards.enumerated()), id: \.element.id) { index, card in
                                            SwipeableCardRow(
                                                card: card, variant: .cardDrawer,
                                                onTap: {
                                                    selectedCard = card
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                        showOneMust = true
                                                    }
                                                },
                                                onComplete: {
                                                    completeCard(card)
                                                },
                                                onDelete: {
                                                    deleteCard(card)
                                                },
                                                onSetPriority: {
                                                    let generator = UINotificationFeedbackGenerator()
                                                    generator.notificationOccurred(.success)
                                                    // Remove from exclusion list so it can be a priority again
                                                    withAnimation {
                                                        excludedFromPriorityIds.removeAll { $0 == card.id }
                                                    }
                                                    saveState()
                                                    print("DEBUG: Set priority for card \(card.id), excluded count: \(excludedFromPriorityIds.count)")
                                                }
                                            )
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                    .padding(.bottom, 40 + geometry.safeAreaInsets.bottom)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: drawerState.height(screenHeight: geometry.size.height) + geometry.safeAreaInsets.bottom)
                        .background(AppColor.Surface.secondary)
                        .cornerRadius(20, corners: [.topLeft, .topRight])
                        .ignoresSafeArea(edges: .bottom)
                        .offset(y: geometry.safeAreaInsets.bottom)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadState()
            Analytics.shared.trackAppOpened()
            // Reset drawer state on app open
            drawerState = .small
        }
        .onChange(of: cards) { _, _ in
            saveState()
        }
        .onChange(of: priorityCardIds) { _, _ in
            saveState()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                syncWidgetCompletions()
            }
        }
        .onChange(of: isSearchFocused) { _, focused in
            if focused {
                // Expand drawer to full screen when search is focused
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    drawerState = .large
                }
            }
        }
        .onOpenURL { url in
            // Handle deep links from widget
            if url.scheme == "miranda" {
                if url.host == "capture" {
                    newCardText = ""
                    startWithDictation = false
                    showCreateModal = true
                } else if url.host == "card" {
                    // Open specific card
                    let pathComponents = url.pathComponents
                    if pathComponents.count > 1,
                       let cardIdString = pathComponents.last,
                       let cardId = UUID(uuidString: cardIdString),
                       let card = cards.first(where: { $0.id == cardId }) {
                        selectedCard = card
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showOneMust = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAnalytics) {
            AnalyticsDebugView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                onShowAnalytics: {
                    showSettings = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAnalytics = true
                    }
                },
                onDeleteAll: {
                    clearAllCards()
                },
                onResetOnboarding: {
                    resetOnboarding()
                },
                currentPriorityCard: priorityCards.first,
                lastCapture: cards.max(by: { $0.timestamp < $1.timestamp }),
                hasCaptures: !cards.isEmpty
            )
        }
        .sheet(isPresented: $showWidgetInstructions) {
            NavigationView {
                WidgetInstructionsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showWidgetInstructions = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showCreateModal) {
            CreateCardModal(
                text: $newCardText,
                startWithDictation: startWithDictation,
                onSave: {
                    createCard()
                },
                onCancel: {
                    newCardText = ""
                    showCreateModal = false
                    startWithDictation = false
                }
            )
        }
        .sheet(isPresented: $showPriorityPicker) {
            PriorityPickerView(
                cards: cards.sorted { $0.timestamp > $1.timestamp }.filter { !priorityCardIds.contains($0.id) },
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
                    // Don't set as priority
                    Analytics.shared.trackCardCreated(hasEmoji: card.emoji != nil)
                    pendingCard = nil
                }
            }
        } message: {
            if let card = pendingCard {
                Text("\(card.emoji ?? "")  \(card.simplifiedText)")
            }
        }
    }
    
    private func createCard() {
        guard !newCardText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let originalText = newCardText
        let actionText = actionTransformEnabled ? transformToAction(originalText) : originalText
        let newCard = Card(
            originalText: originalText,
            simplifiedText: actionText,
            emoji: nil,
            timestamp: Date()
        )
        
        // Add the card
        cards.append(newCard)
        
        
        // Count current priorities (cards not excluded)
        let currentPriorityCount: Int = cards.filter { !excludedFromPriorityIds.contains($0.id) }.count
        
        // If already 3+ priorities, exclude new card from priority (goes to drawer)
        if currentPriorityCount > 3 {
            excludedFromPriorityIds.append(newCard.id)
        }
            
            // Track analytics
            Analytics.shared.trackCardCreated(hasEmoji: false)
            
            // Reset and close modal
            newCardText = ""
            showCreateModal = false
    }
    
    private func transformToAction(_ text: String) -> String {
        let lowercased = text.lowercased()
        
        // Check each keyword in the action transformations
        for (keyword, action) in actionTransformations {
            if lowercased.contains(keyword) {
                // If the text already starts with the action, return as-is
                if lowercased.hasPrefix(action.lowercased()) {
                    return text
                }
                
                // If action is complete (like "Drink more water"), return it
                if !action.contains("for") && !action.contains("about") && !action.contains("the") {
                    // Check if it's a complete action
                    let words = action.split(separator: " ")
                    if words.count >= 3 || action == "Buy groceries" || action == "Drink more water" {
                        return action
                    }
                }
                
                // Otherwise, append the original text
                return "\(action) \(text)"
            }
        }
        
        // No transformation found, return original
        return text
    }
    
    
    private func findEmoji(for text: String) -> String? {
        let lowercased = text.lowercased()
        
        // Check each keyword in the emoji map
        for (keyword, emoji) in emojiMap {
            if lowercased.contains(keyword) {
                return emoji
            }
        }
        
        return nil
    }
    
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
        // Add to priorities if not full (max 3)
        if !priorityCardIds.contains(cardId) && priorityCardIds.count < 3 {
            priorityCardIds.append(cardId)
        }
    }
    
    private func completeCard(_ card: Card) {
        // Calculate time to complete
        let timeToComplete = Date().timeIntervalSince(card.timestamp)
        Analytics.shared.trackCardCompleted(timeToComplete: timeToComplete)
        
        // Remove the card
        withAnimation {
            cards.removeAll { $0.id == card.id }
            
            // If it was a priority, remove it from priorities
            priorityCardIds.removeAll { $0 == card.id }
        }
    }
    
    private func deleteCard(_ card: Card) {
        // Remove the card without tracking completion
        withAnimation {
            cards.removeAll { $0.id == card.id }
            
            // If it was a priority, remove it from priorities
            priorityCardIds.removeAll { $0 == card.id }
        }
    }
    
    private func completePriorityCard(_ card: Card) {
        // Show tortoise animation
        showCompleteTortoise = true
        
        // Calculate time to complete
        let timeToComplete = Date().timeIntervalSince(card.timestamp)
        Analytics.shared.trackCardCompleted(timeToComplete: timeToComplete)
        
        // After animation, remove card
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                cards.removeAll { $0.id == card.id }
                priorityCardIds.removeAll { $0 == card.id }
                showCompleteTortoise = false
            }
            
            // If we have less than 3 priorities and there are remaining cards, ask to set new priority
            if priorityCardIds.count < 3 && !cards.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showPriorityPicker = true
                }
            }
        }
    }
    
    private func clearAllCards() {
        withAnimation {
            cards.removeAll()
            priorityCardIds.removeAll()
        }
    }
    
    private func resetOnboarding() {
        withAnimation {
            // Reset all onboarding states
            widgetOnboardingDismissed = false
            captureOnboardingDismissed = false
            priorityCardIds.removeAll()
            excludedFromPriorityIds.removeAll()
            
            // Clear UserDefaults for onboarding
            UserDefaults.standard.removeObject(forKey: "widgetOnboardingDismissed")
            UserDefaults.standard.removeObject(forKey: "captureOnboardingDismissed")
            UserDefaults.standard.removeObject(forKey: "priorityCardIds")
            UserDefaults.standard.removeObject(forKey: "excludedFromPriorityIds")
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    
    // MARK: - Persistence
    
    private func saveState() {
        let encoder = JSONEncoder()
        
        // Save cards
        if let cardsData = try? encoder.encode(cards) {
            UserDefaults.standard.set(cardsData, forKey: "cards")
        }
        
        // Save priority IDs (up to 3)
        let priorityStrings = priorityCardIds.map { $0.uuidString }
        UserDefaults.standard.set(priorityStrings, forKey: "priorityCardIds")
        
        // Save onboarding dismissed states
        UserDefaults.standard.set(widgetOnboardingDismissed, forKey: "widgetOnboardingDismissed")
        UserDefaults.standard.set(captureOnboardingDismissed, forKey: "captureOnboardingDismissed")
        
        // Save excluded from priority IDs
        let excludedStrings = excludedFromPriorityIds.map { $0.uuidString }
        UserDefaults.standard.set(excludedStrings, forKey: "excludedFromPriorityIds")
        
        // Save to shared storage for widget - only first 3 priorities show in widget
        let eligibleForPriority: [Card] = sortedCards.filter { !excludedFromPriorityIds.contains($0.id) }
        let widgetPriorityCards = Array(eligibleForPriority.prefix(3))
        let firstPriorityCard = widgetPriorityCards.first
        SharedCardManager.shared.saveCurrentCard(firstPriorityCard) // For backward compatibility
        SharedCardManager.shared.savePriorityCards(widgetPriorityCards) // First 3 priority cards for widget
        SharedCardManager.shared.saveAllCards(cards) // All cards for widget intents
        
        // Request widget refresh
        #if canImport(WidgetKit)
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    private func loadState() {
        let decoder = JSONDecoder()
        
        // Load cards
        if let cardsData = UserDefaults.standard.data(forKey: "cards"),
           let loadedCards = try? decoder.decode([Card].self, from: cardsData) {
            cards = loadedCards
        }
        
        // Load priority IDs
        if let priorityStrings = UserDefaults.standard.array(forKey: "priorityCardIds") as? [String] {
            priorityCardIds = priorityStrings.compactMap { UUID(uuidString: $0) }
        }
        
        // Load onboarding dismissed states
        widgetOnboardingDismissed = UserDefaults.standard.bool(forKey: "widgetOnboardingDismissed")
        captureOnboardingDismissed = UserDefaults.standard.bool(forKey: "captureOnboardingDismissed")
        
        // Load excluded from priority IDs
        if let excludedStrings = UserDefaults.standard.array(forKey: "excludedFromPriorityIds") as? [String] {
            excludedFromPriorityIds = excludedStrings.compactMap { UUID(uuidString: $0) }
        }
        
        // Sync widget completions — remove cards that were completed via widget
        syncWidgetCompletions()
    }
    
    /// Check the shared container for cards completed via the widget and remove
    /// them from the main app state. The widget can only write to the shared
    /// container (App Group UserDefaults), not to the app's own UserDefaults.standard.
    /// Without this sync, completed cards reappear when the app re-saves state.
    private func syncWidgetCompletions() {
        let completedCards = SharedCardManager.shared.loadCompletedCards()
        guard !completedCards.isEmpty else { return }
        
        let completedIDs = Set(completedCards.map { $0.id })
        
        // Remove completed cards from app state
        let beforeCount = cards.count
        cards.removeAll { completedIDs.contains($0.id) }
        priorityCardIds.removeAll { completedIDs.contains($0) }
        
        // Only save if something changed
        if cards.count != beforeCount {
            // Clear the completed cards list so we don't re-process them
            SharedCardManager.shared.clearCompletedCards()
        }
    }
}

// MARK: - Tortoise Completion Animation

struct TortoiseCompletionView: View {
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            AppColor.scrim
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Tortoise emoji with animation
                Text("🐢")
                    .font(.system(size: 100))
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                
                Text("Well done!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColor.Text.inverse)
                
                Text("Slow and steady wins the race")
                    .font(.system(size: 18))
                    .foregroundColor(AppColor.Text.inverse)
            }
            .opacity(opacity)
            .onAppear {
                // Scale and fade in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    scale = 1.2
                    opacity = 1.0
                }
                
                // Gentle rotation
                withAnimation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatCount(2, autoreverses: true)
                ) {
                    rotation = 10
                }
                
                // Bounce back scale
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                    scale = 1.0
                }
            }
        }
    }
}

// MARK: - Recent Captures Drawer

struct RecentCapturesDrawer: View {
    let cards: [Card]
    @Binding var showAllCards: Bool
    let maxVisibleCards: Int
    let onCardTap: (Card) -> Void
    let onComplete: (Card) -> Void
    let onDelete: (Card) -> Void
    let onSetPriority: (Card) -> Void
    let onCreateCard: (String, Bool) -> Void
    
    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @AppStorage("audioInputEnabled") private var audioInputEnabled: Bool = false
    
    private let collapsedHeight: CGFloat = 120
    private let expandedHeight: CGFloat = 600
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColor.dragHandle)
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                // Header with action buttons
                HStack {
                    Text("Recent")
                        .font(AppFont.title2)
                        .foregroundColor(AppColor.Text.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Audio button (if enabled)
                        if audioInputEnabled {
                            Button(action: {
                                onCreateCard("", true)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(AppColor.Surface.button)
                                        .frame(width: 56, height: 56)
                                    
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 56, height: 56)
                                    
                                    Circle()
                                        .stroke(AppColor.Border.subtle.opacity(0.6), lineWidth: 1.5)
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(AppColor.Text.primary)
                                }
                                .shadow(color: AppColor.shadow.opacity(0.15), radius: 6, x: 0, y: 3)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Add button
                        Button(action: {
                            onCreateCard("", false)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppColor.Surface.button)
                                    .frame(width: 56, height: 56)
                                
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 56, height: 56)
                                
                                Circle()
                                    .stroke(AppColor.Border.subtle.opacity(0.6), lineWidth: 1.5)
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(AppColor.Text.primary)
                            }
                            .shadow(color: AppColor.shadow.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Cards list or empty state
                if cards.isEmpty {
                    // No recent captures - just empty space
                    VStack(spacing: 16) {
                        Text("No Recent Notes")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(AppColor.Text.secondary)
                            .padding(.vertical, 20)
                                .frame(maxWidth: .infinity, alignment: .top)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                                if showAllCards || index < maxVisibleCards {
                                    SwipeableCardRow(
                                        card: card, variant: .cardDrawer,
                                        onTap: {
                                            onCardTap(card)
                                        },
                                        onComplete: {
                                            onComplete(card)
                                        },
                                        onDelete: {
                                            onDelete(card)
                                        },
                                        onSetPriority: {
                                            onSetPriority(card)
                                        }
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            // "More" button
                            if cards.count > maxVisibleCards && !showAllCards {
                                Button(action: {
                                    withAnimation {
                                        showAllCards = true
                                    }
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("More")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppColor.Text.secondary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 40 + geometry.safeAreaInsets.bottom)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColor.Surface.primary)
                    .shadow(color: AppColor.shadowMedium, radius: 20, x: 0, y: -8)
            )
            .frame(height: collapsedHeight + offset + dragOffset)
            .frame(maxHeight: expandedHeight)
            .offset(y: geometry.size.height - (collapsedHeight + offset + dragOffset))
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = -value.translation.height
                    }
                    .onEnded { value in
                        let translation = -value.translation.height
                        
                        if translation > 100 {
                            // Expand
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                offset = expandedHeight - collapsedHeight
                            }
                        } else if translation < -50 && offset > 0 {
                            // Collapse
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                offset = 0
                            }
                        } else {
                            // Stay in current state
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if offset > (expandedHeight - collapsedHeight) / 2 {
                                    offset = expandedHeight - collapsedHeight
                                } else {
                                    offset = 0
                                }
                            }
                        }
                    }
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Empty Priority Slot

struct EmptyPrioritySlot: View {
    let height: CGFloat
    let slotNumber: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: min(80, height * 0.2))
                    .fill(AppColor.slotFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: min(80, height * 0.2))
                            .strokeBorder(lineWidth: 2)
                            .foregroundColor(AppColor.slotStroke)
                    )
                
                VStack(spacing: height > 200 ? 12 : 6) {
                    // Circular lightbulb button in center
                    ZStack {
                        Circle()
                            .fill(AppColor.slotCircle)
                            .frame(width: min(80, height * 0.3), height: min(80, height * 0.3))
                        
                        Image(systemName: "lightbulb")
                            .font(.system(size: min(32, height * 0.12), weight: .medium))
                            .foregroundColor(AppColor.slotIcon)
                    }
                    
                    // Slot indicator
                    if height > 150 {
                        Text("Priority \(slotNumber)")
                            .font(.system(size: min(13, height * 0.04), weight: .medium))
                            .foregroundColor(AppColor.slotLabel)
                    }
                }
            }
        }
        .frame(height: height)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Dismissible Onboarding Card (Empty State)

struct DismissibleOnboardingCard: View {
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dismiss button (swipe left reveals)
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        offset = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onDismiss()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColor.Action.destructive)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(AppColor.Text.tertiary)
                    }
                }
                .padding(.trailing, 20)
                .opacity(offset < -15 ? 1 : 0)
            }
            
            // Main card - reuses CardOnboarding
            CardOnboarding()
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { gesture in
                            let translation = gesture.translation.width
                            if translation < 0 {
                                offset = max(-100, translation)
                            }
                        }
                        .onEnded { gesture in
                            let translation = gesture.translation.width
                            
                            if translation < -50 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    offset = -80
                                }
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    offset = 0
                                }
                            }
                        }
                )
                .onTapGesture {
                    if offset != 0 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            offset = 0
                        }
                    }
                }
        }
    }
}

// MARK: - Widget Onboarding Card

struct WidgetOnboardingCard: View {
    let height: CGFloat
    let priorityCard: Card?
    let onDismiss: () -> Void
    let onLearnMore: () -> Void
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dismiss button (swipe left reveals)
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        offset = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onDismiss()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColor.Action.destructive)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(AppColor.Text.tertiary)
                    }
                }
                .padding(.trailing, 20)
                .opacity(offset < -15 ? 1 : 0)
            }
            
            // Main card - use CardOnboarding style but with widget text
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    Text("Add the Widget to your home screen to keep your priorities visible (max 3). ")
                    + Text("Easy-peasy.").bold()
                }
                .font(.system(size: 18))
                .foregroundColor(AppColor.Text.primary)
                .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(25)
            .frame(height: height)
            .background(
                LinearGradient(
                    colors: CardVariant.cardOnboarding.gradientColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(35)
            .shadow(color: AppColor.shadow, radius: 3, x: 0, y: 3)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { gesture in
                        let translation = gesture.translation.width
                        if translation < 0 {
                            offset = max(-100, translation)
                        }
                    }
                    .onEnded { gesture in
                        let translation = gesture.translation.width
                        
                        if translation < -50 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                offset = -80
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                offset = 0
                            }
                        }
                    }
            )
            .onTapGesture {
                if offset != 0 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        offset = 0
                    }
                } else {
                    onLearnMore()
                }
            }
        }
        .frame(height: height)
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
        NavigationView {
            if cards.isEmpty {
                // Empty state - no cards available to set as priority
                VStack(spacing: 32) {
                    Spacer()
                    
                    Image(systemName: "tray")
                        .font(.system(size: 60))
                        .foregroundColor(AppColor.emptyStateIcon)
                    
                    VStack(spacing: 12) {
                        Text("No other captures")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppColor.Text.primary)
                        
                        Text("Capture something new to set as a priority")
                            .font(.system(size: 15))
                            .foregroundColor(AppColor.Text.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    HStack(spacing: 16) {
                        // Audio capture button (if enabled) - icon only
                        if audioInputEnabled {
                            Button(action: {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onCaptureVoice()
                                }
                            }) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppColor.Text.primary)
                                    .frame(width: 60, height: 60)
                                    .background(AppColor.Surface.secondary)
                                    .clipShape(Circle())
                            }
                        }
                        
                        // Main capture button
                        Button(action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onCaptureText()
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                Text("Note")
                                    .font(.system(size: 20, weight: .bold))
                            }
                            .foregroundColor(AppColor.Text.inverse)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(AppColor.Text.primary)
                            .clipShape(Capsule())
                        }
                    }
                    
                    Spacer()
                }
                .navigationTitle("Set Priority")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            } else {
                // Show list of available cards
            List {
                ForEach(cards) { card in
                    Button(action: {
                        onSelect(card)
                    }) {
                        HStack(spacing: 16) {
                            if let emoji = card.emoji {
                                Text(emoji)
                                    .font(.system(size: 32))
                            }
                            
                            Text(card.simplifiedText)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColor.Text.primary)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Image(systemName: "lightbulb")
                                .font(.system(size: 20))
                                .foregroundColor(AppColor.Text.secondary)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Set Priority")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Hero Card View

struct HeroCardView: View {
    let card: Card
    let height: CGFloat
    var variant: CardVariant = .cardDefault
    let onTap: () -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onRemovePriority: () -> Void
    let onLongPress: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var isLongPressing: Bool = false
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background actions
            HStack {
                // Remove priority button (right swipe reveals this)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        offset = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onRemovePriority()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColor.Action.destructive)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "lightbulb.slash.fill")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(AppColor.Action.destructiveIcon)
                    }
                }
                .padding(.leading, 20)
            .opacity(offset > 15 ? 1 : 0)
                
                Spacer()
                
                // Action buttons (left swipe reveals these)
                HStack(spacing: 12) {
                    // Green checkmark/done button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            offset = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onComplete()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppColor.Action.complete)
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(AppColor.Text.inverse)
                        }
                    }
                    
                    // Red trash/delete button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            offset = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onDelete()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppColor.Action.destructive)
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "trash.fill")
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(AppColor.Text.tertiary)
                        }
                    }
                }
                .padding(.trailing, 20)
                .opacity(offset < -15 ? 1 : 0)
            }
            .animation(.easeOut(duration: 0.2), value: offset)
            
            // Main card using CardComponent
            CardComponent(
                text: card.simplifiedText,
                variant: variant,
                minHeight: height
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if offset != 0 {
                    // If swiped, tap to close
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        offset = 0
                    }
                } else if !isDragging && !isLongPressing {
                    onTap()
                }
            }
            .onLongPressGesture(minimumDuration: 0.4, perform: {
                onLongPress()
            }, onPressingChanged: { isPressing in
                isLongPressing = isPressing
            })
            .offset(x: offset)
            .animation(isDragging ? .none : .spring(response: 0.35, dampingFraction: 0.75), value: offset)
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onChanged { gesture in
                        let horizontal = abs(gesture.translation.width)
                        let vertical = abs(gesture.translation.height)
                        
                        // Only respond to clearly horizontal swipes (3x ratio, min 40px)
                        guard horizontal > 40 && horizontal > vertical * 3 else { return }
                        
                        isDragging = true
                        let translation = gesture.translation.width
                        
                        if !isLongPressing {
                            offset = max(-140, min(100, translation))
                        }
                    }
                    .onEnded { gesture in
                        let horizontal = abs(gesture.translation.width)
                        let vertical = abs(gesture.translation.height)
                        
                        // Only process if it was clearly horizontal
                        guard horizontal > 40 && horizontal > vertical * 3 else {
                            isDragging = false
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                offset = 0
                            }
                            return
                        }
                        
                        isDragging = false
                        let translation = gesture.translation.width
                        
                        if translation > 60 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                offset = 100
                            }
                        } else if translation < -60 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                offset = -140
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .frame(height: height)
        .scaleEffect(isLongPressing ? 1.03 : scale)
        .opacity(opacity)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isLongPressing)
        .onDrag {
            // Provide drag data
            onLongPress() // Ensure draggedCard is set
            return NSItemProvider(object: card.id.uuidString as NSString)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .onChange(of: card.id) { _, _ in
            // Animate when card changes
            scale = 0.9
            opacity = 0
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Card Drop Delegate

struct CardDropDelegate: DropDelegate {
    let destinationIndex: Int
    @Binding var draggedCard: Card?
    @Binding var priorityCardIds: [UUID]
    let cards: [Card]
    let onReorder: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedCard = draggedCard,
              let sourceIndex = priorityCardIds.firstIndex(of: draggedCard.id) else {
            self.draggedCard = nil
            return false
        }
        
        if sourceIndex != destinationIndex {
            // Reorder the priority IDs
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                let id = priorityCardIds.remove(at: sourceIndex)
                priorityCardIds.insert(id, at: destinationIndex)
            }
            
            // Strong haptic feedback on successful reorder
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            
            onReorder()
        }
        
        // Clear dragged card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.draggedCard = nil
        }
        
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedCard = draggedCard,
              let sourceIndex = priorityCardIds.firstIndex(of: draggedCard.id),
              sourceIndex != destinationIndex else {
            return
        }
        
        // Medium haptic feedback when hovering over new position
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Live reorder as you drag (smooth preview)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            let id = priorityCardIds.remove(at: sourceIndex)
            priorityCardIds.insert(id, at: destinationIndex)
        }
    }
    
    func dropExited(info: DropInfo) {
        // Optional: could add subtle feedback when leaving a drop zone
    }
}

// MARK: - Swipeable Card Row

struct SwipeableCardRow: View {
    let card: Card
    var variant: CardVariant = .cardDefault
    let onTap: () -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onSetPriority: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var dragDirection: DragDirection? = nil
    
    private enum DragDirection { case horizontal, vertical }
    
    var body: some View {
        ZStack {
            // Background actions
            HStack {
                // Yellow priority button (left side - swipe right)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        offset = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onSetPriority()
                    }
                }) {
                ZStack {
                    Circle()
                        .fill(AppColor.Action.priority)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(AppColor.Text.inverse)
                    }
                }
                .padding(.leading, 16)
                .opacity(offset > 20 ? 1 : 0)
                
                Spacer()
                
                // Archive button (right side - swipe left)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        offset = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onComplete() // Archive action (reusing complete handler for now)
                    }
                }) {
                    ZStack {
                        // Color base
                        Circle()
                            .fill(AppColor.Action.archive)
                            .frame(width: 50, height: 50)
                        
                        // Material glass effect on top
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 50, height: 50)
                            .background(.thinMaterial)
                        
                        // Stroke
                        Circle()
                            .stroke(AppColor.Action.archive.opacity(0.5), lineWidth: 2)
                            .frame(width: 50, height: 50)
                        
                        // Icon
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColor.Text.inverse)
                    }
                    .shadow(color: AppColor.Action.archive.opacity(0.4), radius: 10, x: 0, y: 4)
                    .compositingGroup()
                    .clipShape(Circle())
                }
                .padding(.trailing, 16)
                .opacity(offset < -20 ? 1 : 0)
            }
            
            // Main card using CardComponent
            CardComponent(
                text: card.simplifiedText,
                variant: variant,
                minHeight: 100,
                fontSize: 18,
                horizontalPadding: 20,
                verticalPadding: 20
            )
            .offset(x: offset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { gesture in
                        if dragDirection == nil {
                            dragDirection = abs(gesture.translation.width) > abs(gesture.translation.height)
                                ? .horizontal : .vertical
                        }
                        guard dragDirection == .horizontal else { return }
                        isDragging = true
                        offset = max(-140, min(120, gesture.translation.width))
                    }
                    .onEnded { gesture in
                        defer { dragDirection = nil }
                        guard dragDirection == .horizontal else { return }
                        isDragging = false
                        let translation = gesture.translation.width
                        
                        if translation > 50 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                offset = 100
                            }
                        } else if translation < -50 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                offset = -140
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                offset = 0
                            }
                        }
                    }
            )
            .onTapGesture {
                if offset != 0 {
                    // If swiped, tap to close
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        offset = 0
                    }
                } else if !isDragging {
                    onTap()
                }
            }
        }
    }
}

// MARK: - Card Row View

struct CardRowView: View {
    let card: Card
    let isOneMust: Bool
    let isPriority: Bool
    let opacity: Double
    let onTap: () -> Void
    let onComplete: () -> Void
    let onSetOneMust: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Emoji
            if let emoji = card.emoji {
                Text(emoji)
                    .font(.system(size: 24))
            }
            
            // Text content
            Text(card.simplifiedText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColor.Text.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(AppColor.Surface.secondary)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .opacity(opacity)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Create Card Modal

struct CreateCardModal: View {
    @Binding var text: String
    let startWithDictation: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    
    let allCommonHints = [
        "Flush the toilet 🚽",
        "Dance for 10 seconds 💃",
        "Don't forget your keys 🔑",
        "Prepare slides for presentation 📊",
        "Buy an umbrella ☂️",
        "Charge your phone 🔋",
        "Take your medicine 💊",
        "Water the plants 🪴",
        "Call mom 📞",
        "Pay the bills 💳",
        "Check the mail 📬",
        "Lock the door 🔐",
        "Turn off the lights 💡",
        "Take out the trash 🗑️",
        "Feed the pet 🐕",
        "Bring reusable bags 🛍️",
        "Set an alarm ⏰",
        "Backup your files 💾",
        "Reply to that email 📧",
        "Schedule dentist appointment 🦷"
    ]
    
    @State private var commonHints: [String] = []
    
    let randomSuggestions = [
        "Compliment your coffee mug ☕️",
        "Name all the colors you can see 🌈",
        "Count backwards from 10 in Spanish 🇪🇸",
        "Do a silly walk to the kitchen 🚶",
        "Smell a lemon 🍋",
        "High-five yourself 🙌",
        "Whisper 'good job' to your plant 🪴",
        "Touch something blue 💙",
        "Make a weird face in the mirror 😜",
        "Pet an imaginary dog 🐕",
        "Sing one word of your favorite song 🎵",
        "Stretch like a cat 🐱",
        "Blink 20 times really fast 👁️",
        "Say 'potato' in 3 different accents 🥔",
        "Spin around three times slowly 🌀",
        "Name your shoes out loud 👟",
        "Wave at something random 👋",
        "Hum the Jeopardy theme 🎶",
        "Balance on one foot for 10 seconds 🦩",
        "Make up a word and use it in a sentence 💭",
        "Count how many pens you have ✍️",
        "Tap your nose 7 times 👃",
        "Say the alphabet backwards from G 🔤",
        "Wiggle your toes 🦶",
        "Name three things you're grateful for 🙏",
        "Do 5 jumping jacks 🤸",
        "Drink a glass of water 💧",
        "Take 3 deep breaths 🫁",
        "Look out the window for 30 seconds 🪟",
        "Write your name with your non-dominant hand ✏️",
        "Snap your fingers 10 times 🫰",
        "Touch your elbows together 💪",
        "Make a bird sound 🐦",
        "Pretend you're a robot for 15 seconds 🤖",
        "Organize one thing on your desk 📎"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Input field - using UITextView wrapper to ensure keyboard appears
                KeyboardTextField(text: $text, placeholder: "What do you want to capture?")
                    .frame(minHeight: 120)
                    .cornerRadius(12)
                
                // Quick suggestions below input
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(commonHints, id: \.self) { hint in
                        Button(action: {
                            text = hint
                        }) {
                            HStack {
                                Text(hint)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppColor.Text.primary)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColor.Text.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColor.Surface.tertiary)
                            .cornerRadius(10)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onCancel) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onSave) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                // Generate random button above keyboard
                ToolbarItem(placement: .keyboard) {
                    Button(action: {
                        text = randomSuggestions.randomElement() ?? ""
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "dice.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Generate")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(AppColor.Text.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .onAppear {
                // Pick 3 random hints
                commonHints = Array(allCommonHints.shuffled().prefix(3))
            }
        }
    }
}


struct OneMustCardView: View {
    let card: Card
    let isNewCard: Bool
    let isPriority: Bool
    let onDismiss: () -> Void
    let onSetPriority: () -> Void
    let onRemovePriority: (() -> Void)?
    let onComplete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(spacing: 50) {
                    Spacer(minLength: 50)
                    
                    // Emoji
                    if let emoji = card.emoji {
                        Text(emoji)
                            .font(.system(size: 120))
                    }
                    
                    // Text (scrollable)
                    Text(card.simplifiedText)
                        .font(AppFont.title1)
                        .foregroundColor(AppColor.Text.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer(minLength: 120)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Fixed bottom toolbar with action buttons
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    Divider()
                    
                    if !isPriority {
                        Button(action: { onComplete() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .heavy))
                                Text("Complete")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(AppColor.Text.inverse)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                ZStack {
                                    AppColor.Action.complete
                                    Color.clear.background(.thinMaterial)
                                }
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AppColor.Action.complete.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: AppColor.Action.complete.opacity(0.4), radius: 8, x: 0, y: 4)
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        Button(action: {
                            onSetPriority()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                onDismiss()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 18, weight: .heavy))
                                Text("Turn this on")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(AppColor.Text.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                ZStack {
                                    AppColor.Action.priority
                                    Color.clear.background(.thinMaterial)
                                }
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AppColor.Action.priority.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: AppColor.Action.priority.opacity(0.4), radius: 8, x: 0, y: 4)
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    } else {
                        Button(action: { onComplete() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .heavy))
                                Text("Complete")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(AppColor.Text.inverse)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                ZStack {
                                    AppColor.Action.complete
                                    Color.clear.background(.thinMaterial)
                                }
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AppColor.Action.complete.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: AppColor.Action.complete.opacity(0.4), radius: 8, x: 0, y: 4)
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        if let removePriority = onRemovePriority {
                            Button(action: { removePriority() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.slash.fill")
                                        .font(.system(size: 18, weight: .heavy))
                                    Text("Turn this off")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(AppColor.Text.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    ZStack {
                                        AppColor.Text.primary.opacity(0.25)
                                        Color.clear.background(.thinMaterial)
                                    }
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(AppColor.Text.primary.opacity(0.3), lineWidth: 1.5)
                                )
                                .shadow(color: AppColor.Text.primary.opacity(0.2), radius: 6, x: 0, y: 3)
                                .clipShape(Capsule())
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }
                    }
                }
                .background(AppColor.Surface.primary)
            }
            
            // X close button -- always visible with liquid glass style
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    onDismiss()
                }
            }) {
                ZStack {
                    // Color base
                    Circle()
                        .fill(AppColor.Text.primary.opacity(0.3))
                        .frame(width: 44, height: 44)
                    
                    // Material glass effect on top
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                        .background(.thinMaterial)
                    
                    // Stroke
                    Circle()
                        .stroke(AppColor.Text.primary.opacity(0.5), lineWidth: 2)
                        .frame(width: 44, height: 44)
                    
                    // Icon
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColor.Icon.foregroundGradient)
                }
                .shadow(color: AppColor.Text.primary.opacity(0.25), radius: 10, x: 0, y: 4)
                .compositingGroup()
                .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 16)
        }
        .background(AppColor.Surface.primary)
    }
}

// MARK: - View Extension for Custom Corner Radius

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ContentView()
}

