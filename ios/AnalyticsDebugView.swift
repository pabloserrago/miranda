import SwiftUI

struct AnalyticsDebugView: View {
    @State private var stats: [String: Any] = [:]
    @State private var recentEvents: [[String: Any]] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Stats Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(.title2)
                            .bold()
                        
                        ForEach(Array(stats.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.body)
                                Spacer()
                                Text("\(stats[key] as? Int ?? 0)")
                                    .font(.body.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Recent Events Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Events")
                            .font(.title2)
                            .bold()
                        
                        ForEach(Array(recentEvents.enumerated()), id: \.offset) { index, event in
                            VStack(alignment: .leading, spacing: 4) {
                                if let eventName = event["event"] as? String {
                                    Text(eventName)
                                        .font(.headline)
                                }
                                
                                if let timestamp = event["timestamp"] as? TimeInterval {
                                    Text(formatDate(timestamp))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                ForEach(Array(event.keys.filter { $0 != "event" && $0 != "timestamp" }.sorted()), id: \.self) { key in
                                    Text("\(key): \(String(describing: event[key] ?? ""))")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
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

