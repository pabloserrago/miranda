import SwiftUI

/// First-launch onboarding: capture a first note, see it on the widget
/// preview, personalize the app. Forward-only — step 1 advances by saving
/// a note, and only "Finish" on step 3 completes the flow (no skip).
struct OnboardingView: View {
    @Binding var newCardText: String
    /// The note captured in step 1 (top priority), shown on step 2.
    let latestCard: Card?
    let onSaveNote: () -> Void
    let onFinish: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var step: Int = 1
    @State private var showNoteSheet: Bool = false
    @State private var showWidgetInstructions: Bool = false

    @AppStorage("audioInputEnabled") private var audioInputEnabled: Bool = false
    @AppStorage("completionAnimationEnabled") private var completionAnimationEnabled: Bool = true
    @AppStorage("backgroundTheme") private var backgroundThemeRaw: String = BackgroundTheme.standard.rawValue
    @AppStorage(AppIconManager.storageKey) private var selectedAppIconRaw: String = AppIconOption.default.rawValue

    private var selectedAppIcon: AppIconOption {
        AppIconOption(rawValue: selectedAppIconRaw) ?? .default
    }

    var body: some View {
        ZStack {
            // The live app background: picking a swatch on step 3 writes
            // backgroundTheme, so the change is visible immediately.
            NoisyBackgroundView(
                config: colorScheme == .dark ? .defaultDark : .default,
                scrollOffset: 0,
                theme: BackgroundTheme(rawValue: backgroundThemeRaw) ?? .standard
            )
            .ignoresSafeArea()

            switch step {
            case 1: stepOne
            case 2: stepTwo
            default: stepThree
            }
        }
        .sheet(isPresented: $showNoteSheet) {
            CreateCardModal(
                text: $newCardText,
                startWithDictation: false,
                onSave: {
                    onSaveNote()
                    showNoteSheet = false
                    withAnimation { step = 2 }
                },
                onCancel: {
                    newCardText = ""
                    showNoteSheet = false
                }
            )
            .presentationBackground(Material.Surface.secondary)
        }
        .sheet(isPresented: $showWidgetInstructions) {
            NavigationStack {
                HowToAddWidgetView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showWidgetInstructions = false }
                        }
                    }
            }
            .presentationBackground(Material.Surface.secondary)
        }
    }

    // MARK: - Step 1: capture the first note

    private var stepOne: some View {
        OnboardingPage(
            iconAssetName: selectedAppIcon.previewAssetName,
            title: String(localized: "What's on your mind?"),
            subtitle: String(localized: "Capture anything, we'll take it from here.")
        ) {
            EmptyView()
        }
        .safeAreaInset(edge: .bottom) {
            BottomCTA(
                title: String(localized: "Add your first note"),
                systemImage: "plus",
                identifier: "onboarding-add-first-note",
                action: { showNoteSheet = true }
            )
        }
    }

    // MARK: - Step 2: widget upsell showing the captured note

    private var stepTwo: some View {
        OnboardingPage(
            title: String(localized: "See what matters most today."),
            subtitle: String(localized: "Your priorities will be visible on your homepage widget.")
        ) {
            WidgetPreview(card: latestCard)
        }
        .safeAreaInset(edge: .bottom) {
            BottomCTA(
                title: String(localized: "Add widget to home page"),
                identifier: "onboarding-add-widget",
                action: { showWidgetInstructions = true },
                secondaryTitle: String(localized: "Continue"),
                secondaryIdentifier: "onboarding-continue",
                secondaryAction: { withAnimation { step = 3 } }
            )
        }
    }

    // MARK: - Step 3: personalization

    private var stepThree: some View {
        OnboardingPage(
            iconAssetName: selectedAppIcon.previewAssetName,
            title: String(localized: "Make Miranda yours!"),
            subtitle: String(localized: "A calm space starts with what feels right to you."),
            contentHorizontalPadding: 16
        ) {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select background")
                        .font(AppFont.label)
                        .foregroundColor(Material.Text.secondary)
                    BackgroundThemePicker()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Select your app icon")
                        .font(AppFont.label)
                        .foregroundColor(Material.Text.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(AppIconOption.allCases) { option in
                                Button {
                                    selectAppIcon(option)
                                } label: {
                                    AppIconTile(option: option, isSelected: option == selectedAppIcon)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Personalize your notes")
                        .font(AppFont.label)
                        .foregroundColor(Material.Text.secondary)

                    Group {
                        Toggle(isOn: $audioInputEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "mic.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Voice capture")
                            }
                        }
                        .toggleHaptic(audioInputEnabled)

                        Toggle(isOn: $completionAnimationEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(AppFont.icon)
                                    .foregroundColor(Material.Text.primary)
                                    .frame(width: 24, height: 24)
                                Text("Completion animation")
                            }
                        }
                        .toggleHaptic(completionAnimationEnabled)
                    }
                    .padding(.vertical, 8)
                    // Same accent tint Settings applies to its list, so the
                    // toggles match Miranda's CTA color instead of iOS green.
                    .tint(Material.Text.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            // Same container treatment as the note editor, so the controls
            // stay readable over the live cloud background.
            .background(Material.Surface.secondary)
            .clipShape(RoundedRectangle(cornerRadius: Material.Shape.input, style: .continuous))
        }
        .safeAreaInset(edge: .bottom) {
            BottomCTA(
                title: String(localized: "Finish"),
                identifier: "onboarding-finish",
                action: { onFinish() }
            )
        }
    }

    private func selectAppIcon(_ option: AppIconOption) {
        guard option != selectedAppIcon else { return }
        selectedAppIconRaw = option.rawValue
        Haptics.toggleOn()
        AppIconManager.apply(option, for: colorScheme)
    }
}

// MARK: - Onboarding Page Template

/// Shared layout for onboarding steps: optional app icon, hero text, body
/// copy, then step-specific content. Short pages center vertically; tall
/// pages (like personalization) scroll.
struct OnboardingPage<Content: View>: View {
    var iconAssetName: String? = nil
    let title: String
    let subtitle: String
    /// Horizontal inset for the step-specific content; hero text stays at 32.
    var contentHorizontalPadding: CGFloat = 32
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Group {
                        if let iconAssetName {
                            Image(iconAssetName)
                                .resizable()
                                .frame(width: 76, height: 76)
                                .clipShape(RoundedRectangle(cornerRadius: Material.Shape.appIcon, style: .continuous))
                        }

                        Text(title)
                            .font(AppFont.title)
                            .foregroundColor(Material.Text.primary)
                            .multilineTextAlignment(.center)

                        Text(subtitle)
                            .font(AppFont.body)
                            .foregroundColor(Material.Text.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)

                    content()
                        .padding(.top, 8)
                        .padding(.horizontal, contentHorizontalPadding)
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geo.size.height)
            }
        }
    }
}

#Preview {
    OnboardingView(
        newCardText: .constant(""),
        latestCard: nil,
        onSaveNote: {},
        onFinish: {}
    )
}
