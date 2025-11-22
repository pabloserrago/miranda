import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), card: Card(
            originalText: "Your priority capture",
            simplifiedText: "Your priority capture",
            emoji: "✨",
            timestamp: Date()
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let card = SharedCardManager.shared.loadCurrentCard()
        let entry = SimpleEntry(date: Date(), card: card)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let card = SharedCardManager.shared.loadCurrentCard()
        let entry = SimpleEntry(date: currentDate, card: card)
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let card: Card?
}

struct OneMustWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if let card = entry.card {
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(card: card)
            case .systemMedium:
                MediumWidgetView(card: card)
            case .systemLarge:
                MediumWidgetView(card: card)
            default:
                SmallWidgetView(card: card)
            }
        } else {
            EmptyWidgetView()
        }
    }
}

struct SmallWidgetView: View {
    let card: Card
    
    var body: some View {
        VStack(spacing: 12) {
            if let emoji = card.emoji {
                Text(emoji)
                    .font(.system(size: 50))
            }
            
            Text(card.simplifiedText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(6)
                .padding(.horizontal, 8)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(uiColor: .systemBackground)
        }
    }
}

struct MediumWidgetView: View {
    let card: Card
    
    var body: some View {
        HStack(spacing: 16) {
            if let emoji = card.emoji {
                Text(emoji)
                    .font(.system(size: 60))
            }
            
            Text(card.simplifiedText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(uiColor: .systemBackground)
        }
    }
}

struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("✨")
                .font(.system(size: 40))
            
            Text("No capture yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Create one in the app")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .containerBackground(for: .widget) {
            Color(uiColor: .systemBackground)
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
        .description("Your current focus capture")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    OneMustWidget()
} timeline: {
    SimpleEntry(date: .now, card: Card(
        originalText: "Send email to team",
        simplifiedText: "Send email to team",
        emoji: "📧",
        timestamp: Date()
    ))
}

