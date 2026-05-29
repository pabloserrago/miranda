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
        defaults?.synchronize()
        
        let cards = SharedCardManager.shared.loadPriorityCards()
        
        if defaults?.string(forKey: "completingCardID") != nil {
            defaults?.removeObject(forKey: "completingCardID")
            defaults?.synchronize()
            
            let freshCards = SharedCardManager.shared.loadPriorityCards()
            
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let entry = SimpleEntry(date: currentDate, priorityCards: freshCards, phase: .normal)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
            return
        }
        
        let entry = SimpleEntry(date: currentDate, priorityCards: cards, phase: .normal)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: — Shared Widget Components

private struct WidgetGradient: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Material.Widget.bg[0], location: 0.0),
                .init(color: Material.Widget.bg[1], location: 0.55),
                .init(color: Material.Widget.bg[2], location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottomTrailing
        )
    }
}

private struct WidgetNoteButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Link(destination: URL(string: "miranda://capture")!) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(AppFont.micro).fontWeight(.semibold)
                Text("Note")
                    .font(AppFont.label).fontWeight(.semibold)
                    .tracking(Material.Typography.Tracking.widgetButton)
            }
            .foregroundColor(Material.Text.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Material.Text.primary)
                    .shadow(color: Material.Elevation.shadow,
                            radius: colorScheme == .dark ? 4 : 3,
                            x: 0, y: 1)
            )
        }
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
        case .accessoryRectangular:
            LockScreenRectangularView(cards: entry.priorityCards)
        case .accessoryInline:
            LockScreenInlineView(cards: entry.priorityCards)
        default:
            CompactWidgetView(cards: entry.priorityCards)
        }
    }
}

// MARK: — Compact Widget (Small)

struct CompactWidgetView: View {
    let cards: [Card]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let card = cards.first {
                Text(card.simplifiedText)
                    .font(AppFont.icon).fontWeight(.heavy)
                    .tracking(Material.Typography.Tracking.widgetCompact)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .foregroundColor(Material.Text.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Capture anything.")
                    .font(AppFont.label)
                    .tracking(Material.Typography.Tracking.widgetLabel)
                    .foregroundColor(Material.Text.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) { WidgetGradient() }
        .widgetURL(cards.first.map { URL(string: "miranda://card/\($0.id.uuidString)")! })
    }
}

// MARK: — Medium Widget (Tortoise Architecture)

struct MediumWidgetView: View {
    let entry: SimpleEntry

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                taskList
                    .padding(.top, 14)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if entry.priorityCards.isEmpty {
                WidgetNoteButton()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            } else {
                Link(destination: URL(string: "miranda://capture")!) {
                    Text("+ Note")
                        .font(AppFont.caption)
                        .foregroundColor(Material.Text.primary.opacity(0.55))
                }
                .padding(.trailing, 14)
                .padding(.bottom, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) { WidgetGradient() }
    }

    @ViewBuilder
    private var taskList: some View {
        if entry.priorityCards.isEmpty {
            emptyReadyView
        } else {
            let visibleCards = Array(entry.priorityCards.prefix(2))
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(visibleCards.enumerated()), id: \.element.id) { index, card in
                    TaskRowView(
                        card: card,
                        rank: index
                    )
                    .padding(.horizontal, 14)
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
            .animation(.easeOut(duration: 0.32), value: entry.priorityCards.map(\.id))
        }
    }

    @ViewBuilder
    private var emptyReadyView: some View {
        Text("Capture anything.")
            .font(AppFont.label)
            .tracking(Material.Typography.Tracking.widgetLabel)
            .foregroundColor(Material.Text.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .padding(.bottom, 44)
    }
}

// MARK: — Task Row with Rank-based Typography

struct TaskRowView: View {
    let card: Card
    let rank: Int

    private var font: Font { rank == 0 ? AppFont.widgetHero : AppFont.caption }
    private var tracking: CGFloat { rank == 0 ? Material.Typography.Tracking.widgetHero : Material.Typography.Tracking.widgetCaption }
    
    private var textColor: Color {
        switch rank {
        case 0: return Material.Text.primary
        default: return Material.Text.secondary
        }
    }

    var body: some View {
        Link(destination: URL(string: "miranda://card/\(card.id.uuidString)")!) {
            HStack(alignment: .center, spacing: 0) {
                Text(card.simplifiedText)
                    .font(font)
                    .tracking(tracking)
                    .lineLimit(rank == 0 ? 2 : 1)
                    .truncationMode(.tail)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.vertical, rank == 0 ? 4 : 3)
        }
    }
}

// MARK: — Large Widget (Shows all 3 priorities)

struct LargeWidgetView: View {
    let cards: [Card]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if cards.isEmpty {
                Text("Capture anything.")
                    .font(AppFont.label)
                    .tracking(Material.Typography.Tracking.widgetLabel)
                    .foregroundColor(Material.Text.primary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                WidgetNoteButton()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(cards.prefix(3).enumerated()), id: \.element.id) { index, card in
                        LargeTaskRow(card: card, rank: index)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 16)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Link(destination: URL(string: "miranda://capture")!) {
                        Text("+ Note")
                            .font(AppFont.caption)
                            .foregroundColor(Material.Text.primary.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) { WidgetGradient() }
    }
}

// MARK: — Large Task Row

struct LargeTaskRow: View {
    let card: Card
    let rank: Int
    
    private var font: Font { rank == 0 ? AppFont.widgetLargeHero : AppFont.subhead }
    private var tracking: CGFloat { rank == 0 ? Material.Typography.Tracking.widgetLargeHero : Material.Typography.Tracking.widgetSecondary }
    
    private var textColor: Color {
        switch rank {
        case 0: return Material.Text.primary
        default: return Material.Text.secondary
        }
    }
    
    var body: some View {
        Link(destination: URL(string: "miranda://card/\(card.id.uuidString)")!) {
            HStack(alignment: .center, spacing: 0) {
                Text(card.simplifiedText)
                    .font(font)
                    .tracking(tracking)
                    .lineLimit(rank == 0 ? 2 : 1)
                    .truncationMode(.tail)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, rank == 0 ? 8 : 5)
        }
    }
}

struct EmptyWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Capture anything.")
                    .font(AppFont.label)
                    .tracking(Material.Typography.Tracking.widgetLabel)
                    .lineSpacing(1.42)
                    .foregroundColor(Material.Text.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, 70)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    WidgetNoteButton()
                        .padding(.horizontal, 13)
                }
            }
            .padding(.bottom, 13)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) { WidgetGradient() }
    }
}

// MARK: — Lock Screen Rectangular Widget

struct LockScreenRectangularView: View {
    let cards: [Card]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if cards.isEmpty {
                Text("No priorities yet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(cards.prefix(2).enumerated()), id: \.element.id) { index, card in
                    Label {
                        Text(card.simplifiedText)
                            .lineLimit(1)
                            .font(index == 0 ? .caption.weight(.semibold) : .caption2)
                    } icon: {
                        Image(systemName: index == 0 ? "1.circle.fill" : "2.circle")
                            .widgetAccentable()
                    }
                    .foregroundStyle(index == 0 ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                }
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(cards.first.map { URL(string: "miranda://card/\($0.id.uuidString)")! })
    }
}

// MARK: — Lock Screen Inline Widget

struct LockScreenInlineView: View {
    let cards: [Card]

    var body: some View {
        if let card = cards.first {
            Label(card.simplifiedText, systemImage: "checkmark.circle")
                .widgetAccentable()
        } else {
            Label("No priorities", systemImage: "tray")
        }
    }
}

// MARK: — Widget Entry Point

@main
struct OneMustWidget: Widget {
    let kind: String = "OneMustWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            OneMustWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Miranda")
        .description("Your priority captures")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryRectangular, .accessoryInline])
    }
}

#Preview(as: .accessoryRectangular) {
    OneMustWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        priorityCards: [
            Card(originalText: "Email", simplifiedText: "Reply to that email", emoji: "📧", timestamp: Date()),
            Card(originalText: "Trash", simplifiedText: "Take out the trash", emoji: "🗑️", timestamp: Date()),
        ],
        phase: .normal
    )
    SimpleEntry(date: .now, priorityCards: [], phase: .normal)
}

#Preview(as: .accessoryInline) {
    OneMustWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        priorityCards: [
            Card(originalText: "Email", simplifiedText: "Reply to that email", emoji: "📧", timestamp: Date()),
        ],
        phase: .normal
    )
    SimpleEntry(date: .now, priorityCards: [], phase: .normal)
}

#Preview(as: .systemMedium) {
    OneMustWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        priorityCards: [
            Card(originalText: "Email", simplifiedText: "Send email Reply to that email", emoji: "📧", timestamp: Date()),
            Card(originalText: "Trash", simplifiedText: "Take out the trash", emoji: "🗑️", timestamp: Date()),
            Card(originalText: "Backup", simplifiedText: "Backup your files", emoji: "💾", timestamp: Date()),
        ],
        phase: .normal
    )
    
    SimpleEntry(
        date: .now.addingTimeInterval(1),
        priorityCards: [
            Card(originalText: "Email", simplifiedText: "Send email Reply to that email", emoji: "📧", timestamp: Date()),
            Card(originalText: "Trash", simplifiedText: "Take out the trash", emoji: "🗑️", timestamp: Date()),
            Card(originalText: "Backup", simplifiedText: "Backup your files", emoji: "💾", timestamp: Date()),
        ],
        phase: .completing(id: UUID().uuidString)
    )
    
    SimpleEntry(
        date: .now.addingTimeInterval(1.5),
        priorityCards: [
            Card(originalText: "Trash", simplifiedText: "Take out the trash", emoji: "🗑️", timestamp: Date()),
            Card(originalText: "Backup", simplifiedText: "Backup your files", emoji: "💾", timestamp: Date()),
        ],
        phase: .normal
    )
    
    SimpleEntry(
        date: .now.addingTimeInterval(3),
        priorityCards: [],
        phase: .normal
    )
}
