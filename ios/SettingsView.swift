import SwiftUI

struct SettingsView: View {
    let onShowAnalytics: () -> Void
    let onDeleteAll: () -> Void
    let onResetOnboarding: () -> Void
    let currentPriorityCard: Card?
    let lastCapture: Card?
    let hasCaptures: Bool
    @Environment(\.dismiss) var dismiss
    @AppStorage("audioInputEnabled") private var audioInputEnabled: Bool = false
    @AppStorage("actionTransformEnabled") private var actionTransformEnabled: Bool = false
    @AppStorage("completionAnimationEnabled") private var completionAnimationEnabled: Bool = true
    @State private var showDeleteConfirm: Bool = false
    @State private var showCopiedToast: Bool = false
    @State private var showFeedback: Bool = false
    @State private var showFeedbackSentToast: Bool = false
    
    private var previewCard: Card? {
        currentPriorityCard ?? lastCapture
    }
    
    var body: some View {
            NavigationStack {
                List {
                    // 1. Widget
                    Section {
                        // iPhone widget preview mockup
                        VStack(spacing: 12) {
                            // Simulated iPhone home screen
                            ZStack {
                                // Background gradient (like iOS wallpaper)
                                LinearGradient(
                                    colors: [Material.Status.info.opacity(0.1), Material.Status.success.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                
                                VStack(spacing: 20) {
                                    // Status bar area
                                    HStack {
                                        Text("9:41")
                                            .font(AppFont.caption).fontWeight(.semibold)
                                            .foregroundColor(Material.Text.primary.opacity(0.8))
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
                                            .font(AppFont.body).fontWeight(.semibold)
                                            .foregroundColor(Material.Text.primary)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 12)
                                    }
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 140)
                                    .background(Material.Surface.primary)
                                    .cornerRadius(Material.Shape.drawer)
                                    .shadow(color: Material.Elevation.shadow, radius: 6, x: 0, y: 3)
                                    .padding(.horizontal, 24)
                                    
                                    // iOS app icons below
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                        AppIcon(name: "Photos", icon: "photo.fill.on.rectangle.fill", color: Material.Status.error)
                                        AppIcon(name: "Messages", icon: "message.fill", color: Material.Status.success)
                                        AppIcon(name: "Mail", icon: "envelope.fill", color: Material.Status.info)
                                        AppIcon(name: "Phone", icon: "phone.fill", color: Material.Status.success)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                                    
                                    Spacer()
                                }
                            }
                            .frame(height: 320)
                            .cornerRadius(Material.Shape.drawer)
                            .overlay(
                                RoundedRectangle(cornerRadius: Material.Shape.drawer)
                                    .stroke(Material.Decoration.tertiary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Material.Surface.primary)
                        
                        NavigationLink(destination: WidgetInstructionsView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "questionmark.circle")
                                    .font(AppFont.icon)
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("How to Add Widget")
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Material.Surface.primary)
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
                                    .font(AppFont.icon)
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Audio Input")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                        
                        Toggle(isOn: $actionTransformEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "wand.and.stars")
                                    .font(AppFont.icon)
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Transform to Actions")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                        
                        Toggle(isOn: $completionAnimationEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(AppFont.icon)
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Completion Animation")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
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
                                    .cornerRadius(Material.Shape.x2)
                            } else {
                                RoundedRectangle(cornerRadius: Material.Shape.x2)
                                    .fill(Material.Text.accent)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("M")
                                            .font(AppFont.icon)
                                            .foregroundColor(Material.Text.inverse)
                                    )
                            }
                            
                            Text("App Icon")
                            
                            Spacer()
                            
                            Text("Soon")
                                .font(AppFont.label)
                                .foregroundColor(Material.Text.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Material.Text.secondary.opacity(0.15))
                                .cornerRadius(Material.Shape.x2)
                        }
                        .opacity(0.6)
                        .listRowBackground(Material.Surface.primary)
                    }
                    
                    // 4. Submit a Request
                    Section {
                        Button(action: {
                            showFeedback = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(AppFont.icon)
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Submit a Request")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AppFont.caption)
                                    .foregroundColor(Material.Text.secondary)
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                    }
                    
                    // 5. Delete All
                    Section {
                        Button(role: .destructive, action: {
                            showDeleteConfirm = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.fill")
                                    .font(AppFont.icon)
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Delete All Notes")
                            }
                        }
                        .disabled(!hasCaptures)
                        .opacity(hasCaptures ? 1.0 : 0.5)
                        .listRowBackground(Material.Surface.primary)
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
                                    .font(AppFont.icon)
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(Material.Text.secondary)
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                    }
                    
                    // 7. Developer Settings
                    Section {
                        NavigationLink(destination: DevComponentsView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "hammer.fill")
                                    .font(AppFont.icon)
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("View Components")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                        
                        Button(action: onShowAnalytics) {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.bar.fill")
                                    .font(AppFont.icon)
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Analytics Debug")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                        
                        Button(action: onResetOnboarding) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(AppFont.icon)
                                    .imageScale(.medium)
                                    .frame(width: 24, height: 24)
                                Text("Reset Onboarding")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                    } header: {
                        Text("Developer")
                    }
                }
            .font(AppFont.body)
            .tint(Material.Text.accent)
            .scrollContentBackground(.hidden)
            .background(Material.Surface.tertiary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
                .alert("Delete All Notes?", isPresented: $showDeleteConfirm) {
                    Button("Delete All", role: .destructive) {
                        onDeleteAll()
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete all your notes. This action cannot be undone.")
                }
                .sheet(isPresented: $showFeedback) {
                    FeedbackView(onSuccess: {
                        showFeedbackSentToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showFeedbackSentToast = false
                        }
                    })
                }
            }
            .toast(isPresented: $showCopiedToast, message: "Version copied")
            .toast(isPresented: $showFeedbackSentToast, message: "Feedback sent")
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
        .background(Material.Surface.tertiary)
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(AppFont.body).bold()
                .foregroundColor(Material.Text.inverse)
                .frame(width: 28, height: 28)
                .background(Material.Text.accent)
                .clipShape(Circle())
            
            Text(text)
                .font(AppFont.body)
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
                RoundedRectangle(cornerRadius: Material.Shape.appIcon)
                    .fill(color)
                    .frame(width: 56, height: 56)
                
                RoundedRectangle(cornerRadius: Material.Shape.appIcon)
                    .strokeBorder(Material.Decoration.tertiary, lineWidth: 2)
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(AppFont.headline).fontWeight(.regular)
                    .foregroundColor(Material.Text.inverse)
            }
            
            Text(name)
                .font(AppFont.caption)
                .foregroundColor(Material.Text.primary)
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
                        .font(AppFont.label)
                        .foregroundColor(Material.Text.secondary)
                    
                    CardComponent(
                        text: "Test example of something to do.",
                        variant: .cardDefault,
                        minHeight: 200
                    )
                }
                
                // Card Drawer
                VStack(alignment: .leading, spacing: 8) {
                    Text("card-drawer")
                        .font(AppFont.label)
                        .foregroundColor(Material.Text.secondary)
                    
                    CardComponent(
                        text: "Drawer card with plain background (adaptive for light/dark mode).",
                        variant: .cardDrawer,
                        minHeight: 100
                    )
                }
                
                // Card Onboarding
                VStack(alignment: .leading, spacing: 8) {
                    Text("card-onboarding")
                        .font(AppFont.label)
                        .foregroundColor(Material.Text.secondary)
                    
                    CardOnboarding(minHeight: 200)
                }
                
                // Card Boost
                VStack(alignment: .leading, spacing: 8) {
                    Text("card-boost")
                        .font(AppFont.label)
                        .foregroundColor(Material.Text.secondary)
                    
                    CardBoost(
                        text: "Test example of something to do.",
                        label: "Limitless",
                        minHeight: 200
                    )
                }
                
                // Card Default with long text
                VStack(alignment: .leading, spacing: 8) {
                    Text("card-default (long text)")
                        .font(AppFont.label)
                        .foregroundColor(Material.Text.secondary)
                    
                    CardComponent(
                        text: "This is a much longer piece of text that should demonstrate how the card handles overflow and truncation when there's too much content to display.",
                        variant: .cardDefault,
                        minHeight: 200
                    )
                }
            }
            .padding(20)
        }
        .background(Material.Surface.tertiary)
        .navigationTitle("Components")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView(onShowAnalytics: {}, onDeleteAll: {}, onResetOnboarding: {}, currentPriorityCard: nil, lastCapture: nil, hasCaptures: true)
}

#Preview("Dev Components") {
    NavigationView {
        DevComponentsView()
    }
}

