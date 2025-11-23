import WidgetKit
import SwiftUI

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

// MARK: - Compact Widget (Small - Scrollable)

struct CompactWidgetView: View {
    let cards: [Card]
    
    var body: some View {
        ZStack {
            if let card = cards.first {
                // Show first priority (can be extended to scroll through all)
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
                    
                    Spacer()
                    
                    // Indicator dots if multiple priorities
                    if cards.count > 1 {
                        HStack(spacing: 4) {
                            ForEach(0..<min(cards.count, 3), id: \.self) { index in
                                Circle()
                                    .fill(index == 0 ? Color.primary : Color.secondary.opacity(0.3))
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                }
                .padding()
            }
        }
        .containerBackground(for: .widget) {
            Color.yellow
        }
    }
}

// MARK: - Medium Widget (Shows up to 2 priorities + capture button)

struct MediumWidgetView: View {
    let cards: [Card]
    
    var body: some View {
        HStack(spacing: 8) {
            // Show up to 2 priority cards
            ForEach(Array(cards.prefix(2).enumerated()), id: \.element.id) { index, card in
                VStack(spacing: 6) {
                    if let emoji = card.emoji {
                        Text(emoji)
                            .font(.system(size: 32))
                    }
                    
                    Text(card.simplifiedText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(Color.yellow)
                .cornerRadius(20)
            }
            
            // Capture button
            Link(destination: URL(string: "miranda://capture")!) {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                    
                    Text("Capture")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(uiColor: .secondarySystemFill))
                .cornerRadius(20)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(red: 0x22/255, green: 0x22/255, blue: 0x22/255)
        }
    }
}

// MARK: - Large Widget (Shows all 3 priorities in grid)

struct LargeWidgetView: View {
    let cards: [Card]
    
    var body: some View {
        VStack(spacing: 12) {
            // Show all 3 priority slots
            ForEach(0..<3, id: \.self) { index in
                if index < cards.count {
                    let card = cards[index]
                    HStack(spacing: 12) {
                        // Priority number badge
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.yellow)
                            .clipShape(Circle())
                        
                        // Emoji
                        if let emoji = card.emoji {
                            Text(emoji)
                                .font(.system(size: 28))
                        }
                        
                        // Text
                        Text(card.simplifiedText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                } else {
                    // Empty slot
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                        
                        Image(systemName: "lightbulb")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("Empty slot")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                }
            }
            
            // Capture button at bottom
            Link(destination: URL(string: "miranda://capture")!) {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                    Text("Capture")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.yellow)
                .cornerRadius(16)
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(red: 0x22/255, green: 0x22/255, blue: 0x22/255)
        }
    }
}

struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No priorities set")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            
            Link(destination: URL(string: "miranda://capture")!) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text("Capture")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.yellow)
                .cornerRadius(20)
            }
        }
        .containerBackground(for: .widget) {
            Color(red: 0x22/255, green: 0x22/255, blue: 0x22/255)
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

