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
    @Environment(\.openURL) private var openURL
    @AppStorage("audioInputEnabled") private var audioInputEnabled: Bool = false
    @AppStorage("actionTransformEnabled") private var actionTransformEnabled: Bool = false
    @AppStorage("hyphenSplitEnabled") private var hyphenSplitEnabled: Bool = false
    @AppStorage("completionAnimationEnabled") private var completionAnimationEnabled: Bool = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage(AppIconManager.storageKey) private var selectedAppIconRaw: String = AppIconOption.default.rawValue
    @State private var showDeleteConfirm: Bool = false
    @State private var showCopiedToast: Bool = false
    @State private var showFeedback: Bool = false
    @State private var showFeedbackSentToast: Bool = false
    @State private var widgetTab: Int = 0
    
    private var previewCard: Card? {
        currentPriorityCard ?? lastCapture
    }

    private var captureFooterText: String {
        var sentences: [String] = []
        if audioInputEnabled {
            sentences.append("Audio button enabled.")
        }
        if actionTransformEnabled {
            sentences.append("Miranda will convert captures into actionable tasks.")
        }
        if hyphenSplitEnabled {
            sentences.append("Each line starting with \"-\" becomes its own note.")
        }
        return sentences.joined(separator: " ")
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
                                // Capped: these are pictures of the OS screen at
                                // fixed geometry, not app content, so their text
                                // must not grow with Larger Text.
                                WidgetPreview(card: previewCard)
                                    .dynamicTypeSize(...DynamicTypeSize.large)
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
                                .dynamicTypeSize(...DynamicTypeSize.large)
                                .cornerRadius(Material.Shape.drawer)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Material.Shape.drawer)
                                        .stroke(Material.Decoration.tertiary.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                        .settingsRowBackground(.top)
                        
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
                        .settingsRowBackground(.bottom)
                    }
                    
                    // Spacer between sections
                    Section {}
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .frame(height: 44)

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
                        .settingsRowBackground(.top)
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
                        .settingsRowBackground(.middle)
                        .toggleHaptic(actionTransformEnabled)

                        Toggle(isOn: $hyphenSplitEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "divide.circle")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Split by Hyphens")
                            }
                        }
                        .settingsRowBackground(.bottom)
                        .toggleHaptic(hyphenSplitEnabled)
                    } header: {
                        Text("Capture")
                            .font(AppFont.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Material.Text.primary)
                            .textCase(nil)
                    } footer: {
                        if !captureFooterText.isEmpty {
                            Text(captureFooterText)
                        }
                    }

                    // Spacer between sections
                    Section {}
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .frame(height: 44)

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
                        .settingsRowBackground(.top)
                        .toggleHaptic(completionAnimationEnabled)

                        HStack(spacing: 12) {
                            Image(systemName: "paintpalette.fill")
                                .font(AppFont.icon)
                                .foregroundColor(Material.Text.primary)
                                .frame(width: 24, height: 24)

                            Text("Background")

                            Spacer()

                            BackgroundThemePicker()
                        }
                        .settingsRowBackground(.middle)

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
                        .settingsRowBackground(.middle)

                        NavigationLink(destination: AppIconPickerView()) {
                            HStack(spacing: 12) {
                                Image((AppIconOption(rawValue: selectedAppIconRaw) ?? .default).previewAssetName)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: Material.Shape.x2, style: .continuous))

                                Text("App Icon")
                            }
                        }
                        .settingsRowBackground(.bottom)
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
                        .frame(height: 44)

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
                        .settingsRowBackground(.single)
                        .toggleHaptic(notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled {
                                onEnableReminders()
                            } else {
                                NotificationManager.shared.cancelAllNotifications()
                            }
                        }
                    }
                    
                    // 4. Submit a Request (requires the Supabase backend)
                    if Secrets.supabaseEnabled {
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
                            .settingsRowBackground(.single)
                        }
                    }
                    
                    // 5. Rate the App
                    Section {
                        Button(action: {
                            ReviewManager.shared.recordUserRated()
                            Analytics.shared.trackReviewStoreOpened(source: "settings")
                            openURL(AppStoreLink.writeReviewURL)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "star.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Rate the App")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(AppFont.caption)
                                    .foregroundColor(Material.Text.secondary)
                            }
                        }
                        .tint(Material.Text.primary)
                        .settingsRowBackground(.single)
                    }

                    // 6. Privacy Policy
                    Section {
                        Link(destination: URL(string: "https://github.com/pabloserrago/miranda/blob/main/PRIVACY.md")!) {
                            HStack(spacing: 12) {
                                Image(systemName: "hand.raised.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(AppFont.caption)
                                    .foregroundColor(Material.Text.secondary)
                            }
                        }
                        .tint(Material.Text.primary)
                        .settingsRowBackground(.single)
                    }
                    
                    // 7. Delete All
                    Section {
                        Button(role: .destructive, action: {
                            showDeleteConfirm = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.fill")
                                    .font(AppFont.icon)
                                    .frame(width: 24, height: 24)
                                Text("Delete All Notes")
                            }
                            // The destructive role would tint the label with the
                            // system red, which does not match the token.
                            .foregroundStyle(Material.Status.error)
                        }
                        .disabled(!hasCaptures)
                        .opacity(hasCaptures ? 1.0 : 0.5)
                        .settingsRowBackground(.single)
                    }
                    
                    // 8. App Version
                    Section {
                        Button(action: {
                            UIPasteboard.general.string = AppInfo.displayVersion
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
                                Text(AppInfo.displayVersion)
                                    .foregroundColor(Material.Text.secondary)
                            }
                        }
                        .tint(Material.Text.primary)
                        .settingsRowBackground(.single)
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
                        .settingsRowBackground(.top)

                        NavigationLink(destination: CloudLabView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "cloud.sun.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Cloud Lab")
                            }
                        }
                        .settingsRowBackground(.middle)
                        
                        Button(action: onShowAnalytics) {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.bar.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Analytics Debug")
                            }
                        }
                        .settingsRowBackground(.middle)
                        
                        Button(action: onResetOnboarding) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Reset Onboarding")
                            }
                        }
                        .settingsRowBackground(.middle)

                        Button(action: onSendTestReminder) {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.badge.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Send Test Reminder")
                            }
                        }
                        .settingsRowBackground(.bottom)
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

// MARK: - Cloud Lab (debug only)

#if DEBUG
/// Live playground for the cloud background shader. Tweak the sliders,
/// then bake values you like into `CloudParams` defaults / `BackgroundTheme`.
struct CloudLabView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var theme: BackgroundTheme = .bloom
    @State private var scale: Double = CloudParams().scale
    @State private var edgeLow: Double = CloudParams().edgeLow
    @State private var edgeHigh: Double = CloudParams().edgeHigh
    @State private var seed: Double = Double(BackgroundTheme.bloom.cloudSeed)
    @State private var grain: Double = 0.30

    private var noiseConfig: NoiseConfig {
        var config: NoiseConfig = colorScheme == .dark ? .defaultDark : .default
        config.bottomOpacity = grain
        return config
    }

    var body: some View {
        ZStack {
            NoisyBackgroundView(
                config: noiseConfig,
                scrollOffset: 0,
                theme: theme,
                cloudParams: CloudParams(
                    scale: scale,
                    edgeLow: edgeLow,
                    edgeHigh: edgeHigh,
                    seed: Float(seed)
                )
            ).ignoresSafeArea()

            VStack(spacing: 16) {
                CardComponent(
                    text: "Liquid Glass preview card.",
                    minHeight: 110
                )

                Spacer()

                controls
            }
            .padding(20)
        }
        .navigationTitle("Cloud Lab")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Picker("Preset", selection: $theme) {
                ForEach(BackgroundTheme.allCases, id: \.rawValue) { theme in
                    Text(theme.label).tag(theme)
                }
            }
            .pickerStyle(.segmented)

            sliderRow("Scale", value: $scale, in: 1...8)
            sliderRow("Low", value: $edgeLow, in: 0...0.5)
            sliderRow("High", value: $edgeHigh, in: 0.5...1)
            sliderRow("Seed", value: $seed, in: 0...10, step: 1)
            sliderRow("Grain", value: $grain, in: 0...0.6)

            Text("scale \(scale, specifier: "%.2f") · edges \(edgeLow, specifier: "%.2f")–\(edgeHigh, specifier: "%.2f") · seed \(Int(seed)) · grain \(grain, specifier: "%.2f")")
                .font(AppFont.caption.monospaced())
                .foregroundColor(Material.Text.secondary)
                .textSelection(.enabled)
        }
        .padding(16)
        .background(Material.Surface.secondary.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: Material.Shape.x3))
    }

    private func sliderRow(
        _ label: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(AppFont.label)
                .foregroundColor(Material.Text.primary)
                .frame(width: 44, alignment: .leading)
            if let step {
                Slider(value: value, in: range, step: step)
            } else {
                Slider(value: value, in: range)
            }
            Text(String(format: "%.2f", value.wrappedValue))
                .font(AppFont.caption.monospaced())
                .foregroundColor(Material.Text.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

#Preview("Cloud Lab") {
    NavigationStack {
        CloudLabView()
    }
}
#endif

#Preview {
    SettingsView(onShowAnalytics: {}, onDeleteAll: {}, onResetOnboarding: {}, onEnableReminders: {}, currentPriorityCard: nil, lastCapture: nil, hasCaptures: true, onSendTestReminder: {})
}

#Preview("Dev Components") {
    NavigationStack {
        DevComponentsView()
    }
}

