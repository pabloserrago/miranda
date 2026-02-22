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
        let defaults = UserDefaults(suiteName: "group.com.pabloserrano.onemust")
        defaults?.synchronize()  // Ensure we read latest writes from Intent
        
        let cards = SharedCardManager.shared.loadPriorityCards()
        
        // Check if a completion was just triggered
        if let completingIDString = defaults?.string(forKey: "completingCardID") {
            // Clear the flag immediately so we don't re-trigger
            defaults?.removeObject(forKey: "completingCardID")
            defaults?.synchronize()
            
            // Intent already removed the card from storage.
            // Cards loaded above may or may not still include it (race condition).
            // Build timeline from current storage state either way.
            let freshCards = SharedCardManager.shared.loadPriorityCards()
            
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let entry = SimpleEntry(date: currentDate, priorityCards: freshCards, phase: .normal)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
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

// MARK: — Compact Widget (Small) - Tortoise Architecture Applied

struct CompactWidgetView: View {
    let cards: [Card]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(intent: CompleteCardIntent(cardId: cards.first?.id.uuidString ?? "")) {
            VStack(alignment: .leading, spacing: 0) {
                if let card = cards.first {
                    // P1 task - centered for small widget
                    Text(card.simplifiedText)
                        .font(.system(size: 20, weight: .heavy))  // 20pt/800 for small widget
                        .tracking(-0.60)  // -0.03em
                        .lineLimit(3)
                        .truncationMode(.tail)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // Empty state
                    Text("Capture anything.")
                        .font(.system(size: 13, weight: .regular))
                        .tracking(-0.156)
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .padding(14)
        }
        .buttonStyle(.plain)
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
                        .init(color: Color(red: 0.976, green: 0.933, blue: 0.855, opacity: 1.0), location: 0.0),
                        .init(color: Color(red: 0.941, green: 0.882, blue: 0.769, opacity: 1.0), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ?
            Color(red: 0.922, green: 0.949, blue: 1.0) :
            Color(red: 0.110, green: 0.078, blue: 0.063)  // #1C1410
    }
}

// MARK: — Medium Widget (Tortoise Architecture)

struct MediumWidgetView: View {
    let entry: SimpleEntry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Tasks anchored to top, fill entire widget
            VStack(alignment: .leading, spacing: 0) {
                taskList
                    .padding(.top, 14)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Note button — absolutely positioned at bottom-right via ZStack alignment
            if entry.priorityCards.isEmpty {
                // Full-width pill for empty state
                noteButton
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            } else {
                // Plain text "+ Note", fixed bottom-right
                Link(destination: URL(string: "miranda://capture")!) {
                    Text("+ Note")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(textColor.opacity(0.55))
                }
                .padding(.trailing, 14)
                .padding(.bottom, 14)
            }
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
        Text("Capture anything.")
            .font(.system(size: 13, weight: .regular))
            .tracking(-0.156)  // -0.012em
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .padding(.bottom, 44)  // Offset upward to center above the pill button
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
                        Color(red: 0.165, green: 0.122, blue: 0.078))  // #2A1F14 - warm dark brown
                    .shadow(color: colorScheme == .dark ? 
                        Color.black.opacity(0.25) : 
                        Color(red: 0.110, green: 0.078, blue: 0.063).opacity(0.18), 
                        radius: colorScheme == .dark ? 4 : 3, 
                        x: 0, y: 1)
            )
        }
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

                Spacer(minLength: 0)
            }
            .padding(.vertical, rank == 0 ? 4 : 3)  // P1: 4pt, P2/P3: 3pt — tight rhythm
        }
        .buttonStyle(.plain)
    }
}

// MARK: — Large Widget (Shows all 3 priorities) - Tortoise Architecture Applied

struct LargeWidgetView: View {
    let cards: [Card]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if cards.isEmpty {
                // Empty state
                Text("Capture anything.")
                    .font(.system(size: 13, weight: .regular))
                    .tracking(-0.156)
                    .foregroundColor(textColor)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                largePillButton
                    .padding(.bottom, 16)
            } else {
                // Task list
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(cards.prefix(3).enumerated()), id: \.element.id) { index, card in
                        LargeTaskRow(card: card, rank: index, colorScheme: colorScheme)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 16)
                
                Spacer()
                
                plainNoteLink
                    .padding(.bottom, 16)
            }
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
                        .init(color: Color(red: 0.976, green: 0.933, blue: 0.855, opacity: 1.0), location: 0.0),
                        .init(color: Color(red: 0.941, green: 0.882, blue: 0.769, opacity: 1.0), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    @ViewBuilder
    private var largePillButton: some View {
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
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ?
                        Color.white.opacity(0.13) :
                        Color(red: 0.165, green: 0.122, blue: 0.078))
                    .shadow(color: colorScheme == .dark ?
                        Color.black.opacity(0.25) :
                        Color(red: 0.110, green: 0.078, blue: 0.063).opacity(0.18),
                        radius: colorScheme == .dark ? 4 : 3,
                        x: 0, y: 1)
            )
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var plainNoteLink: some View {
        HStack {
            Spacer()
            Link(destination: URL(string: "miranda://capture")!) {
                Text("+ Note")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(textColor.opacity(0.55))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }
    
    private var textColor: Color {
        colorScheme == .dark ?
            Color(red: 0.922, green: 0.949, blue: 1.0) :
            Color(red: 0.110, green: 0.078, blue: 0.063)  // #1C1410
    }
}

// MARK: — Large Task Row

struct LargeTaskRow: View {
    let card: Card
    let rank: Int
    let colorScheme: ColorScheme
    
    private var fontSize: CGFloat { rank == 0 ? 24 : 14 }  // P1: 24pt/800, P2/P3: 14pt/400
    private var fontWeight: Font.Weight {
        rank == 0 ? .heavy : .regular
    }
    
    private var textColor: Color {
        if colorScheme == .dark {
            if rank == 0 { return Color(red: 0.922, green: 0.949, blue: 1.0) }
            if rank == 1 { return Color(red: 0.863, green: 0.910, blue: 1.0).opacity(0.85) }
            return Color(red: 0.784, green: 0.843, blue: 1.0)
        } else {
            return Color(red: 0.110, green: 0.078, blue: 0.063)  // #1C1410
        }
    }
    
    var body: some View {
        Button(intent: CompleteCardIntent(cardId: card.id.uuidString)) {
            HStack(alignment: .center, spacing: 0) {
                Text(card.simplifiedText)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .tracking(rank == 0 ? -0.72 : -0.168)
                    .lineLimit(rank == 0 ? 2 : 1)
                    .truncationMode(.tail)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, rank == 0 ? 8 : 5)
        }
        .buttonStyle(.plain)
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
