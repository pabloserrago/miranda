import SwiftUI

struct AnalyticsDebugView: View {
    @State private var stats: [String: Any] = [:]
    @State private var recentEvents: [[String: Any]] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Stats Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(AppFont.headline)
                        
                        ForEach(Array(stats.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(AppFont.body)
                                Spacer()
                                Text("\(stats[key] as? Int ?? 0)")
                                    .font(AppFont.bodyMono)
                                    .foregroundColor(Material.Text.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Material.Surface.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: Material.Shape.x3))
                    
                    // Recent Events Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Events")
                            .font(AppFont.headline)
                        
                        ForEach(Array(recentEvents.enumerated()), id: \.offset) { index, event in
                            VStack(alignment: .leading, spacing: 4) {
                                if let eventName = event["event"] as? String {
                                    Text(eventName)
                                        .font(AppFont.body).bold()
                                }
                                
                                if let timestamp = event["timestamp"] as? TimeInterval {
                                    Text(formatDate(timestamp))
                                        .font(AppFont.caption)
                                        .foregroundColor(Material.Text.secondary)
                                }
                                
                                ForEach(Array(event.keys.filter { $0 != "event" && $0 != "timestamp" }.sorted()), id: \.self) { key in
                                    Text("\(key): \(String(describing: event[key] ?? ""))")
                                        .font(AppFont.caption)
                                        .foregroundColor(Material.Status.info)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Material.Surface.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: Material.Shape.x2))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("📊 Analytics")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                refreshData()
            }
        }
    }
    
    private func refreshData() {
        stats = Analytics.shared.getStats()
        recentEvents = Analytics.shared.getRecentEvents(limit: 20).reversed()
    }
    
    private func formatDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    AnalyticsDebugView()
}

