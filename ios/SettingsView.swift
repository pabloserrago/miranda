import SwiftUI

struct SettingsView: View {
    let onShowAnalytics: () -> Void
    let onDeleteAll: () -> Void
    let currentPriorityCard: Card?
    let lastCapture: Card?
    let hasCaptures: Bool
    @Environment(\.dismiss) var dismiss
    @AppStorage("audioInputEnabled") private var audioInputEnabled: Bool = true
    @AppStorage("actionTransformEnabled") private var actionTransformEnabled: Bool = true
    @State private var showDeleteConfirm: Bool = false
    @State private var showCopiedToast: Bool = false
    
    private var previewCard: Card? {
        currentPriorityCard ?? lastCapture
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                List {
                    // 1. Widget
                    Section {
                        // iPhone widget preview mockup
                        VStack(spacing: 12) {
                            // Simulated iPhone home screen
                            ZStack {
                                // Background gradient (like iOS wallpaper)
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                
                                VStack(spacing: 20) {
                                    // Status bar area
                                    HStack {
                                        Text("9:41")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.primary.opacity(0.8))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 12)
                                    
                                    // Miranda widget (larger card)
                                    VStack(spacing: 12) {
                                        if let emoji = previewCard?.emoji {
                                            Text(emoji)
                                                .font(.system(size: 50))
                                        }
                                        
                                        Text(previewCard?.simplifiedText ?? "Your priority")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 12)
                                    }
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 140)
                                    .background(Color(uiColor: .systemBackground))
                                    .cornerRadius(20)
                                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                                    .padding(.horizontal, 24)
                                    
                                    // iOS app icons below
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                        AppIcon(name: "Photos", icon: "photo.fill.on.rectangle.fill", color: .red)
                                        AppIcon(name: "Messages", icon: "message.fill", color: .green)
                                        AppIcon(name: "Mail", icon: "envelope.fill", color: .blue)
                                        AppIcon(name: "Phone", icon: "phone.fill", color: .green)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                                    
                                    Spacer()
                                }
                            }
                            .frame(height: 320)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                        
                        NavigationLink(destination: WidgetInstructionsView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 20, weight: .bold))
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("How to Add Widget")
                            }
                        }
                        .listRowSeparator(.hidden)
                    } header: {
                        Text("Keep Your Priority Visible")
                    } footer: {
                        Text("This helps you keep your priority visible so you don't forget.")
                    }
                    
                    // Spacer between sections
                    Section {} 
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .frame(height: 20)
                    
                    // 2. Capture
                    Section {
                        Toggle(isOn: $audioInputEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Audio Input")
                            }
                        }
                        
                        Toggle(isOn: $actionTransformEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 20, weight: .bold))
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Transform to Actions")
                            }
                        }
                    } header: {
                        Text("Capture")
                    } footer: {
                        if audioInputEnabled && actionTransformEnabled {
                            Text("Audio button enabled. Miranda will convert captures into actionable tasks.")
                        } else if audioInputEnabled {
                            Text("Audio button enabled.")
                        } else if actionTransformEnabled {
                            Text("Miranda will convert captures into actionable tasks.")
                        } else {
                            Text("Basic capture mode.")
                        }
                    }
                    
                    // 3. App Icon
                    Section {
                        HStack(spacing: 12) {
                            // Current app icon
                            if let appIcon = UIImage(named: "AppIcon") {
                                Image(uiImage: appIcon)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(8)
                            } else {
                                // Fallback: use SF Symbol
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("M")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            Text("App Icon")
                            
                            Spacer()
                            
                            Text("Soon")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .opacity(0.6)
                    }
                    
                    // 4. Submit a Request
                    Section {
                        Button(action: {
                            if let url = URL(string: "mailto:hello@miranda.app?subject=Miranda%20Feedback") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Submit a Request")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // 5. Delete All
                    Section {
                        Button(role: .destructive, action: {
                            showDeleteConfirm = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Delete All Captures")
                            }
                        }
                        .disabled(!hasCaptures)
                        .opacity(hasCaptures ? 1.0 : 0.5)
                    }
                    
                    // 6. App Version
                    Section {
                        Button(action: {
                            UIPasteboard.general.string = "1.0.0"
                            showCopiedToast = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                showCopiedToast = false
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 20, weight: .bold))
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // 7. Developer Settings
                    Section {
                        NavigationLink(destination: DevComponentsView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("View Components")
                            }
                        }
                        
                        Button(action: onShowAnalytics) {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Analytics Debug")
                            }
                        }
                    } header: {
                        Text("Developer")
                    }
                }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
                .alert("Delete All Captures?", isPresented: $showDeleteConfirm) {
                    Button("Delete All", role: .destructive) {
                        onDeleteAll()
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete all your captures. This action cannot be undone.")
                }
            }
            
            // Toast notification
            if showCopiedToast {
                VStack {
                    Spacer()
                    
                    Text("Version copied")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.bottom, 50)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCopiedToast)
            }
        }
    }
}

// MARK: - Widget Instructions View

struct WidgetInstructionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    InstructionStep(number: 1, text: "Long press on home screen, tap +")
                    InstructionStep(number: 2, text: "Search for 'Miranda'")
                    InstructionStep(number: 3, text: "Add the widget to your home screen")
                }
            }
            .padding()
        }
        .navigationTitle("How to Add Widget")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
        }
    }
}

struct AppIcon: View {
    let name: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color)
                    .frame(width: 56, height: 56)
                
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            Text(name)
                .font(.system(size: 11))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Developer Components View

struct DevComponentsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Card Default
                VStack(alignment: .leading, spacing: 8) {
                    Text("card-default")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    CardComponent(
                        text: "Test example of something to do.",
                        variant: .cardDefault,
                        minHeight: 200
                    )
                }
                
                // Card Onboarding
                VStack(alignment: .leading, spacing: 8) {
                    Text("card-onboarding")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    CardOnboarding(minHeight: 200)
                }
                
                // Card Boost
                VStack(alignment: .leading, spacing: 8) {
                    Text("card-boost")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    CardBoost(
                        text: "Test example of something to do.",
                        label: "Limitless",
                        minHeight: 200
                    )
                }
                
                // Card Default with long text
                VStack(alignment: .leading, spacing: 8) {
                    Text("card-default (long text)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    CardComponent(
                        text: "This is a much longer piece of text that should demonstrate how the card handles overflow and truncation when there's too much content to display.",
                        variant: .cardDefault,
                        minHeight: 200
                    )
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Components")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView(onShowAnalytics: {}, onDeleteAll: {}, currentPriorityCard: nil, lastCapture: nil, hasCaptures: true)
}

#Preview("Dev Components") {
    NavigationView {
        DevComponentsView()
    }
}

