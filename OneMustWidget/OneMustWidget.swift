import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), priorityCards: [
            Card(
                originalText: "Your priority capture",
                simplifiedText: "Your priority capture",
                emoji: "✨",
                timestamp: Date()
            )
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let cards = SharedCardManager.shared.loadPriorityCards()
        let entry = SimpleEntry(date: Date(), priorityCards: cards)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let cards = SharedCardManager.shared.loadPriorityCards()
        let entry = SimpleEntry(date: currentDate, priorityCards: cards)
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let priorityCards: [Card]
}

struct OneMustWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if !entry.priorityCards.isEmpty {
            switch widgetFamily {
            case .systemSmall:
                CompactWidgetView(cards: entry.priorityCards)
            case .systemMedium:
                MediumWidgetView(cards: entry.priorityCards)
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

// MARK: - Compact Widget (Small)

struct CompactWidgetView: View {
    let cards: [Card]
    
    var body: some View {
        ZStack {
            if let card = cards.first {
                // Show first priority
                VStack(spacing: 8) {
                    if let emoji = card.emoji {
                        Text(emoji)
                            .font(.system(size: 44))
                    }
                    
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

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                taskList
                Spacer(minLength: 10)
                noteButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.82, green: 0.86, blue: 0.98), location: 0.0),
                    .init(color: Color(red: 0.45, green: 0.60, blue: 0.95), location: 1.0)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
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

    private var allClearView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("That's everything\nfor today.")
                .font(.system(size: 15, weight: .semibold))
                .tracking(-0.4)
                .lineSpacing(2)
                .foregroundColor(.black.opacity(0.9))
                .transition(
                    .opacity
                    .animation(.easeIn(duration: 0.6).delay(0.42))
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noteButton: some View {
        Link(destination: URL(string: "miranda://capture")!) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("Note")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(-0.2)
            }
            .foregroundColor(.white.opacity(0.95))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black)
                    .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 1)
            )
        }
    }
}

// MARK: — Task Row (Rank-based Typography & matchedGeometryEffect)

struct TaskRowView: View {
    let card: Card
    let rank: Int
    let isCompleting: Bool
    let namespace: Namespace.ID

    // Typography scale — rank drives visual hierarchy
    private var fontSize: CGFloat { rank == 0 ? 17 : 15 }
    private var fontWeight: Font.Weight { rank == 0 ? .bold : .medium }
    private var textOpacity: Double {
        if isCompleting { return 0.22 }
        return rank == 2 ? 0.5 : 1.0
    }

    var body: some View {
        Button(intent: CompleteCardIntent(cardId: card.id.uuidString)) {
            HStack(alignment: .center, spacing: 0) {
                Text(card.simplifiedText)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .tracking(rank == 0 ? -0.5 : -0.2)
                    .lineLimit(2)
                    .foregroundColor(Color.black.opacity(textOpacity))
                    .strikethrough(isCompleting, color: .black)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.vertical, rank == 0 ? 8 : 6)
            .padding(.bottom, rank == 0 ? 4 : 0)
        }
        // matchedGeometryEffect: animates task promotion
        .matchedGeometryEffect(id: card.id, in: namespace)
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.32), value: rank)
    }
}




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
                            
                            // Emoji
                            if let emoji = card.emoji {
                                Text(emoji)
                                    .font(.system(size: 24))
                            }
                            
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
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Capture anything that's in your mind.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 0) {
                    Text("Like a dream, idea or to-do. ")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.primary)
                    
                    Text("Simple.")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 70)
            
            // + Note button in bottom right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Link(destination: URL(string: "miranda://capture")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Note")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .clipShape(Capsule())
                    }
                    .padding(12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color(red: 232/255, green: 234/255, blue: 246/255)
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

#Preview(as: .systemSmall) {
    OneMustWidget()
} timeline: {
    SimpleEntry(date: .now, priorityCards: [
        Card(
            originalText: "Send email to team",
            simplifiedText: "Send email to team",
            emoji: "📧",
            timestamp: Date()
        ),
        Card(
            originalText: "Call mom",
            simplifiedText: "Call mom",
            emoji: "📞",
            timestamp: Date()
        )
    ])
}

