import WidgetKit
import SwiftUI
import AppIntents

// ═══════════════════════════════════════════════════════════════
// Miranda Widget — Tortoise Architecture
// Dopamine beat + matchedGeometryEffect promotion
// ═══════════════════════════════════════════════════════════════

// MARK: — Timeline Entry with Phase

enum WidgetPhase: Codable, Equatable {
    case normal
    case completing(id: String)  // UUID as string for Codable
    case allClear
    
    func isCompleting(_ cardID: UUID) -> Bool {
        if case .completing(let id) = self {
            return id == cardID.uuidString
        }
        return false
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let priorityCards: [Card]
    let phase: WidgetPhase
}

// MARK: — Provider with Dual-Entry Timeline

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            priorityCards: [
                Card(
                    originalText: "Your priority capture",
                    simplifiedText: "Your priority capture",
                    emoji: "✨",
                    timestamp: Date()
                )
            ],
            phase: .normal
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let cards = SharedCardManager.shared.loadPriorityCards()
        let entry = SimpleEntry(date: Date(), priorityCards: cards, phase: .normal)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let cards = SharedCardManager.shared.loadPriorityCards()
        
        let phase: WidgetPhase = cards.isEmpty ? .allClear : .normal
        let entry = SimpleEntry(date: currentDate, priorityCards: cards, phase: phase)
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // Push dual-entry timeline on completion (dopamine beat)
    static func pushCompletionTimeline(completedID: UUID) {
        var cards = SharedCardManager.shared.loadPriorityCards()
        
        guard let idx = cards.firstIndex(where: { $0.id == completedID }) else {
            return
        }
        
        // Entry 1 — dopamine beat: task struck through (500ms)
        let entry1 = SimpleEntry(
            date: .now,
            priorityCards: cards,
            phase: .completing(id: completedID.uuidString)
        )
        
        // Entry 2 — promotion: task removed, others promoted
        cards.remove(at: idx)
        SharedCardManager.shared.savePriorityCards(cards)
        
        let phase2: WidgetPhase = cards.isEmpty ? .allClear : .normal
        let entry2 = SimpleEntry(
            date: .now.addingTimeInterval(0.5),
            priorityCards: cards,
            phase: phase2
        )
        
        // Push both entries
        WidgetCenter.shared.reloadTimelines(ofKind: "OneMustWidget")
    }
}

struct OneMustWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @Namespace private var taskNamespace

    var body: some View {
        if !entry.priorityCards.isEmpty || entry.phase == .allClear {
            switch widgetFamily {
            case .systemSmall:
                CompactWidgetView(cards: entry.priorityCards)
            case .systemMedium:
                MediumWidgetView(entry: entry, namespace: taskNamespace)
            case .systemLarge:
                LargeWidgetView(cards: entry.priorityCards)
            default:
                CompactWidgetView(cards: entry.priorityCards)
            }
        } else {
            EmptyWidgetView()
        }
    }
}

// MARK: — Compact Widget (Small)

struct CompactWidgetView: View {
    let cards: [Card]
    
    var body: some View {
        ZStack {
            if let card = cards.first {
                // Show first priority
                VStack(spacing: 8) {
                    Text(card.simplifiedText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(5)
                        .padding(.horizontal, 12)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Complete button (top right)
                VStack {
                    HStack {
                        Spacer()
                        Button(intent: CompleteCardIntent(cardId: card.id.uuidString)) {
                            Image(systemName: "circle")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                    Spacer()
                }
            }
            
            // + button in bottom right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Link(destination: URL(string: "miranda://capture")!) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(uiColor: .secondarySystemFill))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color(uiColor: .systemBackground)
        }
    }
}

// MARK: — Medium Widget (Tortoise Architecture)

struct MediumWidgetView: View {
    let entry: SimpleEntry
    let namespace: Namespace.ID
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                taskList
                Spacer(minLength: 10)
                noteButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            if colorScheme == .dark {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.157, green: 0.216, blue: 0.353, opacity: 0.90), location: 0.0),
                        .init(color: Color(red: 0.086, green: 0.125, blue: 0.235, opacity: 0.96), location: 0.55),
                        .init(color: Color(red: 0.047, green: 0.071, blue: 0.149, opacity: 0.98), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.882, green: 0.910, blue: 0.980), location: 0.0),  // rgba(225,232,250) - lavender-tinted white
                        .init(color: Color(red: 0.737, green: 0.824, blue: 0.957), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    @ViewBuilder
    private var taskList: some View {
        switch entry.phase {
        case .allClear:
            allClearView
        case .normal, .completing:
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(entry.priorityCards.prefix(3).enumerated()), id: \.element.id) { index, card in
                    TaskRowView(
                        card: card,
                        rank: index,
                        isCompleting: entry.phase.isCompleting(card.id),
                        namespace: namespace
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity
                                .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.09)),
                            removal: .opacity
                                .combined(with: .offset(y: -8))
                                .animation(.easeIn(duration: 0.26))
                        )
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var allClearView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("That's everything\nfor today.")
                .font(.system(size: 15, weight: .semibold))
                .tracking(-0.33)  // -0.022em
                .lineSpacing(2)
                .foregroundColor(colorScheme == .dark ? 
                    Color(red: 0.922, green: 0.949, blue: 1.0) : 
                    Color(red: 0.07, green: 0.07, blue: 0.16))
                .transition(
                    .opacity
                    .animation(.easeIn(duration: 0.6).delay(0.42))
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var noteButton: some View {
        Link(destination: URL(string: "miranda://capture")!) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .semibold))
                Text("Note")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(-0.13)
            }
            .foregroundColor(colorScheme == .dark ? 
                Color(red: 0.894, green: 0.933, blue: 1.0, opacity: 0.92) : 
                Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.95))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? 
                        Color.white.opacity(0.13) : 
                        Color(red: 0.10, green: 0.10, blue: 0.18))
                    .shadow(color: colorScheme == .dark ? 
                        Color.black.opacity(0.25) : 
                        Color(red: 0.07, green: 0.07, blue: 0.16).opacity(0.18), 
                        radius: colorScheme == .dark ? 4 : 3, 
                        x: 0, y: 1)
            )
        }
    }
}

// MARK: — Task Row with Rank-based Typography & matchedGeometryEffect

struct TaskRowView: View {
    let card: Card
    let rank: Int
    let isCompleting: Bool
    let namespace: Namespace.ID
    @Environment(\.colorScheme) var colorScheme

    // Typography scale — rank drives visual hierarchy
    private var fontSize: CGFloat { rank == 0 ? 15 : 13 }  // P1: 15pt/650, P2/P3: 13pt/420
    private var fontWeight: Font.Weight {
        if rank == 0 { return .semibold }  // 650 weight
        return rank == 1 ? .regular : .regular  // 420 vs 400 (minimal diff)
    }
    private var textOpacity: Double {
        if isCompleting { return 0.22 }
        return rank == 2 ? 0.36 : 1.0
    }
    
    private var textColor: Color {
        if colorScheme == .dark {
            // Dark mode colors from HTML
            if rank == 0 { return Color(red: 0.922, green: 0.949, blue: 1.0) }  // rgba(235,242,255,1.00)
            if rank == 1 { return Color(red: 0.863, green: 0.910, blue: 1.0).opacity(0.85) }  // rgba(220,232,255,0.85)
            return Color(red: 0.784, green: 0.843, blue: 1.0).opacity(0.38)  // rgba(200,215,255,0.38)
        } else {
            // Light mode
            return Color(red: 0.07, green: 0.07, blue: 0.16)
        }
    }

    var body: some View {
        Button(intent: CompleteCardIntent(cardId: card.id.uuidString)) {
            HStack(alignment: .center, spacing: 0) {
                Text(card.simplifiedText)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .tracking(rank == 0 ? -0.51 : -0.156)  // -0.03em and -0.012em
                    .lineLimit(2)
                    .foregroundColor(isCompleting ? textColor.opacity(0.22) : textColor)
                    .strikethrough(isCompleting, color: textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.vertical, rank == 0 ? 8 : 7)
            .padding(.bottom, rank == 0 ? 3 : 0)
        }
        // matchedGeometryEffect: animates task promotion when previous task is removed
        .matchedGeometryEffect(id: card.id, in: namespace)
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.32), value: rank)
    }
}

// MARK: — Large Widget (Shows all 3 priorities)

struct LargeWidgetView: View {
    let cards: [Card]
    
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                // Show all 3 priority slots
                ForEach(0..<3, id: \.self) { index in
                    if index < cards.count {
                        let card = cards[index]
                        HStack(spacing: 12) {
                            // Complete button (like Reminders)
                            Button(intent: CompleteCardIntent(cardId: card.id.uuidString)) {
                                Image(systemName: "circle")
                                    .font(.system(size: 22, weight: .regular))
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                            
                            // Priority number badge
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 28, height: 28)
                                .background(Color.yellow)
                                .clipShape(Circle())
                            
                            // Text
                            Text(card.simplifiedText)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: .secondarySystemFill))
                        .cornerRadius(16)
                    } else {
                        // Empty slot
                        HStack(spacing: 12) {
                            Image(systemName: "circle")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(.secondary.opacity(0.2))
                            
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.3))
                                .frame(width: 28, height: 28)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .clipShape(Circle())
                            
                            Image(systemName: "lightbulb")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary.opacity(0.3))
                            
                            Text("Empty slot")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: .tertiarySystemFill).opacity(0.5))
                        .cornerRadius(16)
                    }
                }
            }
            .padding(14)
            
            // + button in bottom right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Link(destination: URL(string: "miranda://capture")!) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(uiColor: .secondarySystemFill))
                            .clipShape(Circle())
                    }
                    .padding(12)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color(uiColor: .systemBackground)
        }
    }
}

struct EmptyWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Capture anything.")
                    .font(.system(size: 13, weight: .regular))
                    .tracking(-0.156)  // -0.012em
                    .lineSpacing(1.42)
                    .foregroundColor(Color(red: 0.07, green: 0.07, blue: 0.16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, 70)
            
            // + Note button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Link(destination: URL(string: "miranda://capture")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Note")
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(-0.13)
                        }
                        .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.95))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.10, green: 0.10, blue: 0.18))
                                .shadow(color: Color(red: 0.07, green: 0.07, blue: 0.16).opacity(0.18), radius: 3, x: 0, y: 1)
                        )
                    }
                    .padding(.horizontal, 13)
                }
            }
            .padding(.bottom, 13)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            if colorScheme == .dark {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.157, green: 0.216, blue: 0.353, opacity: 0.90), location: 0.0),
                        .init(color: Color(red: 0.086, green: 0.125, blue: 0.235, opacity: 0.96), location: 0.55),
                        .init(color: Color(red: 0.047, green: 0.071, blue: 0.149, opacity: 0.98), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.882, green: 0.910, blue: 0.980), location: 0.0),  // rgba(225,232,250) - lavender-tinted white
                        .init(color: Color(red: 0.737, green: 0.824, blue: 0.957), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

@main
struct OneMustWidget: Widget {
    let kind: String = "OneMustWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            OneMustWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Miranda")
        .description("Your priority captures")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    OneMustWidget()
} timeline: {
    // Normal state
    SimpleEntry(
        date: .now,
        priorityCards: [
            Card(originalText: "Email", simplifiedText: "Send email Reply to that email", emoji: "📧", timestamp: Date()),
            Card(originalText: "Trash", simplifiedText: "Take out the trash", emoji: "🗑️", timestamp: Date()),
            Card(originalText: "Backup", simplifiedText: "Backup your files", emoji: "💾", timestamp: Date()),
        ],
        phase: .normal
    )
    
    // Completing state — task struck (500ms)
    SimpleEntry(
        date: .now.addingTimeInterval(1),
        priorityCards: [
            Card(originalText: "Email", simplifiedText: "Send email Reply to that email", emoji: "📧", timestamp: Date()),
            Card(originalText: "Trash", simplifiedText: "Take out the trash", emoji: "🗑️", timestamp: Date()),
            Card(originalText: "Backup", simplifiedText: "Backup your files", emoji: "💾", timestamp: Date()),
        ],
        phase: .completing(id: UUID().uuidString)
    )
    
    // After removal — promotion
    SimpleEntry(
        date: .now.addingTimeInterval(1.5),
        priorityCards: [
            Card(originalText: "Trash", simplifiedText: "Take out the trash", emoji: "🗑️", timestamp: Date()),
            Card(originalText: "Backup", simplifiedText: "Backup your files", emoji: "💾", timestamp: Date()),
        ],
        phase: .normal
    )
    
    // All clear
    SimpleEntry(
        date: .now.addingTimeInterval(3),
        priorityCards: [],
        phase: .allClear
    )
}
