import WidgetKit
import SwiftUI
import AppIntents

// ═══════════════════════════════════════════════════════════════
// Miranda Widget — Tortoise Architecture
// Dopamine beat + layout-driven promotion animation
// ═══════════════════════════════════════════════════════════════

// MARK: — Timeline Entry with Phase

enum WidgetPhase: Codable, Equatable {
    case normal
    case completing(id: String)  // UUID as string for Codable
    
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
        
        // Check if a completion was just triggered
        if let completingIDString = UserDefaults(suiteName: "group.com.ahad.oneMust")?.string(forKey: "completingCardID"),
           let completingID = UUID(uuidString: completingIDString),
           let idx = cards.firstIndex(where: { $0.id == completingID }) {
            
            // Clear the flag immediately
            UserDefaults(suiteName: "group.com.ahad.oneMust")?.removeObject(forKey: "completingCardID")
            
            // Entry 1 — dopamine beat: task struck through (500ms)
            let entry1 = SimpleEntry(
                date: currentDate,
                priorityCards: cards,
                phase: .completing(id: completingIDString)
            )
            
            // Entry 2 — promotion: task removed, others promoted
            var updatedCards = cards
            updatedCards.remove(at: idx)
            
            let entry2 = SimpleEntry(
                date: currentDate.addingTimeInterval(0.5),
                priorityCards: updatedCards,
                phase: .normal
            )
            
            // Two-entry arc for dopamine beat
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let timeline = Timeline(entries: [entry1, entry2], policy: .after(nextUpdate))
            completion(timeline)
            return
        }
        
        // Normal single-entry timeline
        let entry = SimpleEntry(date: currentDate, priorityCards: cards, phase: .normal)
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct OneMustWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            CompactWidgetView(cards: entry.priorityCards)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(cards: entry.priorityCards)
        default:
            CompactWidgetView(cards: entry.priorityCards)
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
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tasks anchored to top
            taskList
                .padding(.top, 14)
            
            Spacer()
            
            // + Note fixed at bottom
            noteButton
                .padding(.bottom, 14)
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
                        .init(color: Color(red: 0.976, green: 0.933, blue: 0.855, opacity: 1.0), location: 0.0),  // rgba(249,238,218,1.0) - sand top
                        .init(color: Color(red: 0.941, green: 0.882, blue: 0.769, opacity: 1.0), location: 1.0)   // rgba(240,225,196,1.0) - sand bottom
                    ]),
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    @ViewBuilder
    private var taskList: some View {
        // One state: ready. No distinction between "before" and "after".
        if entry.priorityCards.isEmpty {
            emptyReadyView
        } else {
            let visibleCards = Array(entry.priorityCards.prefix(3))
            VStack(alignment: .leading, spacing: 6) {  // Tighter spacing between rows
                ForEach(Array(visibleCards.enumerated()), id: \.element.id) { index, card in
                    TaskRowView(
                        card: card,
                        rank: index,
                        isCompleting: entry.phase.isCompleting(card.id)
                    )
                    .padding(.horizontal, 14)  // Safe area edge alignment
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
            .animation(.easeOut(duration: 0.32), value: entry.priorityCards.map(\.id))  // Animate layout when array changes
        }
    }

    @ViewBuilder
    private var emptyReadyView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Capture anything.")
                .font(.system(size: 13, weight: .regular))
                .tracking(-0.156)  // -0.012em
                .foregroundColor(textColor)
                .transition(
                    .opacity
                    .animation(.easeIn(duration: 0.6).delay(0.42))
                )
        }
        .padding(.horizontal, 14)  // Safe area edge alignment
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var noteButton: some View {
        HStack {
            Spacer()
            Link(destination: URL(string: "miranda://capture")!) {
                Text("+ Note")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(textColor.opacity(0.55))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)  // Safe area edge alignment
    }
    
    private var textColor: Color {
        colorScheme == .dark ? 
            Color(red: 0.922, green: 0.949, blue: 1.0) : 
            Color(red: 0.110, green: 0.078, blue: 0.063)  // #1C1410
    }

}

// MARK: — Task Row with Rank-based Typography

struct TaskRowView: View {
    let card: Card
    let rank: Int
    let isCompleting: Bool
    @Environment(\.colorScheme) var colorScheme

    // Typography scale — hierarchy through size and weight
    // P1: 28pt/800 ensures 2 full lines render before truncating, hierarchy in weight step
    private var fontSize: CGFloat { rank == 0 ? 28 : 12 }  // P1: 28pt/800, P2/P3: 12pt/400
    private var fontWeight: Font.Weight {
        if rank == 0 { return .heavy }  // 800 weight - commanding
        return .regular  // 400 weight - supporting
    }
    
    private var textColor: Color {
        if colorScheme == .dark {
            // Dark mode colors
            if rank == 0 { return Color(red: 0.922, green: 0.949, blue: 1.0) }  // rgba(235,242,255,1.00)
            if rank == 1 { return Color(red: 0.863, green: 0.910, blue: 1.0).opacity(0.85) }  // rgba(220,232,255,0.85)
            return Color(red: 0.784, green: 0.843, blue: 1.0)  // rgba(200,215,255)
        } else {
            // Light mode - warm dark brown
            return Color(red: 0.110, green: 0.078, blue: 0.063)  // #1C1410
        }
    }
    
    // Completing fade only - NO P3 opacity (WidgetKit drops it, hierarchy by size alone)
    private var finalTextOpacity: Double {
        return isCompleting ? 0.22 : 1.0
    }

    var body: some View {
        Button(intent: CompleteCardIntent(cardId: card.id.uuidString)) {
            HStack(alignment: .center, spacing: 0) {
                Text(card.simplifiedText)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .tracking(rank == 0 ? -0.84 : -0.144)  // P1: -0.03em at 28pt, P2/P3: -0.012em
                    .lineLimit(rank == 0 ? 2 : 1)  // P1: 2 lines before truncating, P2/P3: 1 line
                    .truncationMode(.tail)
                    .foregroundColor(textColor)
                    .opacity(finalTextOpacity)  // Only for completing fade
                    .strikethrough(isCompleting, color: colorScheme == .dark ? 
                        Color(red: 0.922, green: 0.949, blue: 1.0) : 
                        Color(red: 0.110, green: 0.078, blue: 0.063))  // #1C1410
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)  // Allow vertical expansion

                Spacer(minLength: 0)
            }
            .padding(.vertical, rank == 0 ? 6 : 4)  // P1: 6pt (room for 2-line 28pt text), P2/P3: 4pt
        }
        .buttonStyle(.plain)
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
                    .foregroundColor(colorScheme == .dark ? 
                        Color(red: 0.922, green: 0.949, blue: 1.0) : 
                        Color(red: 0.110, green: 0.078, blue: 0.063))  // #1C1410 - dark brown
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
                                .fill(colorScheme == .dark ? 
                                    Color.white.opacity(0.13) : 
                                    Color(red: 0.165, green: 0.122, blue: 0.078))  // #2A1F14 - dark brown
                                .shadow(color: colorScheme == .dark ? 
                                    Color.black.opacity(0.25) : 
                                    Color(red: 0.039, green: 0.173, blue: 0.118).opacity(0.18), 
                                    radius: colorScheme == .dark ? 4 : 3, 
                                    x: 0, y: 1)
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
                        .init(color: Color(red: 0.976, green: 0.933, blue: 0.855, opacity: 1.0), location: 0.0),  // rgba(249,238,218,1.0) - sand top
                        .init(color: Color(red: 0.941, green: 0.882, blue: 0.769, opacity: 1.0), location: 1.0)   // rgba(240,225,196,1.0) - sand bottom
                    ]),
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: — Widget Entry Point
// NOTE: @main belongs in the widget extension target ONLY, not the main app target

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
    
    // Empty/ready state (no distinction between "before" and "after")
    SimpleEntry(
        date: .now.addingTimeInterval(3),
        priorityCards: [],
        phase: .normal
    )
}
