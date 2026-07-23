import SwiftUI

struct SettingsView: View {
    let onShowAnalytics: () -> Void
    let onDeleteAll: () -> Void
    let onResetOnboarding: () -> Void
    let onEnableReminders: () -> Void
    let currentPriorityCard: Card?
    let lastCapture: Card?
    let hasCaptures: Bool
    let onSendTestReminder: () -> Void
    @Environment(\.dismiss) var dismiss
    @AppStorage("audioInputEnabled") private var audioInputEnabled: Bool = false
    @AppStorage("actionTransformEnabled") private var actionTransformEnabled: Bool = false
    @AppStorage("completionAnimationEnabled") private var completionAnimationEnabled: Bool = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var showCopiedToast: Bool = false
    @State private var showFeedback: Bool = false
    @State private var showFeedbackSentToast: Bool = false
    @State private var widgetTab: Int = 0
    
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
                            Picker("", selection: $widgetTab) {
                                Text("Home Screen").tag(0)
                                Text("Lock Screen").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 8)
                            .padding(.top, 4)

                            if widgetTab == 0 {
                                // Home screen preview
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
                                        VStack(spacing: 0) {
                                            Text(previewCard?.simplifiedText ?? "Your priority")
                                                .font(AppFont.widgetHero)
                                                .tracking(Material.Typography.Tracking.widgetHero)
                                                .foregroundColor(Material.Text.primary)
                                                .lineLimit(3)
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.horizontal, 14)
                                        }
                                        .padding(.vertical, 20)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 140)
                                        .background(Material.Surface.primary)
                                        .cornerRadius(Material.Shape.drawer)
                                        .shadow(color: Material.Elevation.shadow.opacity(0.09), radius: 3, x: 0, y: 3)
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
                            } else {
                                // Lock screen preview
                                ZStack {
                                    Color.black.opacity(0.85)

                                    VStack(spacing: 8) {
                                        Text("9:41")
                                            .font(.system(size: 52, weight: .thin))
                                            .foregroundColor(.white)
                                            .padding(.top, 48)

                                        HStack(spacing: 6) {
                                            Image(systemName: "checklist")
                                                .font(AppFont.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                            Text(previewCard?.simplifiedText ?? "Your priority")
                                                .font(AppFont.caption)
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                        }
                                        .padding(.horizontal, 24)

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
                        }
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Material.Surface.primary)
                        
                        NavigationLink(destination: HowToAddWidgetView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "questionmark.circle")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("How to Add Widget")
                            }
                        }
                        .opacity(0.7)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Material.Surface.primary)
                    }
                    
                    // Spacer between sections
                    Section {}
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .frame(height: 30)

                    // 2. Capture
                    Section {
                        Toggle(isOn: $audioInputEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "mic.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Audio Input")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                        .toggleHaptic(audioInputEnabled)
                        
                        Toggle(isOn: $actionTransformEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "wand.and.rays")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Transform to Actions")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                        .toggleHaptic(actionTransformEnabled)
                    } header: {
                        Text("Capture")
                            .font(AppFont.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Material.Text.primary)
                            .textCase(nil)
                    } footer: {
                        if audioInputEnabled && actionTransformEnabled {
                            Text("Audio button enabled. Miranda will convert captures into actionable tasks.")
                        } else if audioInputEnabled {
                            Text("Audio button enabled.")
                        } else if actionTransformEnabled {
                            Text("Miranda will convert captures into actionable tasks.")
                        }
                    }

                    // Spacer between sections
                    Section {}
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .frame(height: 30)

                    // 3. Personalize
                    Section {
                        Toggle(isOn: $completionAnimationEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Completion Animation")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                        .toggleHaptic(completionAnimationEnabled)

                        HStack(spacing: 12) {
                            Image(systemName: "textformat.size.larger")
                                .font(AppFont.icon)
                                .foregroundColor(Material.Text.primary)
                                .frame(width: 24, height: 24)

                            Text("Font Style")

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

                        HStack(spacing: 12) {
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
                    } header: {
                        Text("Personalize")
                            .font(AppFont.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Material.Text.primary)
                            .textCase(nil)
                    }

                    // Spacer between sections
                    Section {}
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .frame(height: 30)

                    // 4. Notifications
                    Section {
                        Toggle(isOn: $notificationsEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Priority Reminders")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                        .toggleHaptic(notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled {
                                onEnableReminders()
                            } else {
                                NotificationManager.shared.cancelAllNotifications()
                            }
                        }
                    }
                    
                    // 4. Submit a Request
                    Section {
                        Button(action: {
                            showFeedback = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.bubble.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Submit a Request")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AppFont.caption)
                                    .foregroundColor(Material.Text.secondary)
                            }
                        }
                        .tint(Material.Text.primary)
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
                                    .foregroundColor(Material.Status.error)
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
                                Image(systemName: "app.shadow")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(Material.Text.secondary)
                            }
                        }
                        .tint(Material.Text.primary)
                        .listRowBackground(Material.Surface.primary)
                    }
                    
                    // 7. Developer Settings (debug builds only)
                    #if DEBUG
                    Section {
                        NavigationLink(destination: DevComponentsView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "hammer.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("View Components")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                        
                        Button(action: onShowAnalytics) {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.bar.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Analytics Debug")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                        
                        Button(action: onResetOnboarding) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Reset Onboarding")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)

                        Button(action: onSendTestReminder) {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.badge.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Send Test Reminder")
                            }
                        }
                        .listRowBackground(Material.Surface.primary)
                    } header: {
                        Text("Developer")
                    }
                    #endif
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

struct HowToAddWidgetView: View {
    var body: some View {
        ZStack {
            Material.Surface.tertiary
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Widget on Home Screen")
                            .font(AppFont.headline)
                            .foregroundColor(Material.Text.primary)
                        InstructionStep(number: 1, text: "Long press on home screen, tap +")
                        InstructionStep(number: 2, text: "Search for 'Miranda'")
                        InstructionStep(number: 3, text: "Add the widget to your home screen")
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Widget on Lock Screen")
                            .font(AppFont.headline)
                            .foregroundColor(Material.Text.primary)
                        InstructionStep(number: 1, text: "Long press on your lock screen")
                        InstructionStep(number: 2, text: "Tap Edit, then tap the clock area")
                        InstructionStep(number: 3, text: "Scroll to Miranda")
                        InstructionStep(number: 4, text: "Choose Rectangular (top 2 priorities) or Inline (top priority only)")
                    }
                }
                .padding()
            }
        }
        .navigationTitle("How to Add Widget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Material.Surface.tertiary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(AppFont.body).bold()
                .foregroundColor(Material.Text.accent)
                .frame(width: 28, height: 28)
                .background(Material.Text.accent.opacity(0.1))
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
        ZStack {
            Material.Surface.tertiary
                .ignoresSafeArea()
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
        }
        .navigationTitle("Components")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Material.Surface.tertiary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#Preview {
    SettingsView(onShowAnalytics: {}, onDeleteAll: {}, onResetOnboarding: {}, onEnableReminders: {}, currentPriorityCard: nil, lastCapture: nil, hasCaptures: true, onSendTestReminder: {})
}

#Preview("Dev Components") {
    NavigationStack {
        DevComponentsView()
    }
}

