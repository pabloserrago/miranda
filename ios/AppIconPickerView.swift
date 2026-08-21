import SwiftUI

/// The selectable app icons, in display order (rows of 3).
enum AppIconOption: String, CaseIterable, Identifiable {
    case `default`
    case dark
    case silhouette
    case bloom
    case meadow
    case dusk
    case turtle
    case hero

    var id: String { rawValue }

    /// Physical alternate-icon asset for the given appearance; `nil` restores the primary icon.
    /// Alternate icons can't auto-switch on the Home Screen, so the adaptive options resolve to a
    /// separate light/dark asset that is applied to match the current appearance.
    func iconName(for scheme: ColorScheme) -> String? {
        switch self {
        case .default:    return nil
        case .dark:       return "AppIconDark"
        case .silhouette: return "AppIconSilhouette"
        case .bloom:      return scheme == .dark ? "AppIconBloomDark" : "AppIconBloomLight"
        case .meadow:     return scheme == .dark ? "AppIconMeadowDark" : "AppIconMeadowLight"
        case .dusk:       return scheme == .dark ? "AppIconDuskDark" : "AppIconDuskLight"
        case .turtle:     return scheme == .dark ? "AppIconTurtleDark" : "AppIconTurtleLight"
        case .hero:       return "AppIconHero"
        }
    }

    /// Imageset used to render the thumbnail in the picker grid.
    var previewAssetName: String {
        switch self {
        case .default:    return "IconPreviewDefault"
        case .dark:       return "IconPreviewDark"
        case .silhouette: return "IconPreviewSilhouette"
        case .bloom:      return "IconPreviewBloom"
        case .meadow:     return "IconPreviewMeadow"
        case .dusk:       return "IconPreviewDusk"
        case .turtle:     return "IconPreviewTurtle"
        case .hero:       return "IconPreviewHero"
        }
    }

    var displayName: String {
        switch self {
        case .default:    return String(localized: "appicon.default",    defaultValue: "Default")
        case .dark:       return String(localized: "appicon.dark",       defaultValue: "Dark")
        case .silhouette: return String(localized: "appicon.silhouette", defaultValue: "Silhouette")
        case .bloom:      return String(localized: "background.bloom",   defaultValue: "Bloom")
        case .meadow:     return String(localized: "background.meadow",  defaultValue: "Meadow")
        case .dusk:       return String(localized: "background.dusk",    defaultValue: "Dusk")
        case .turtle:     return String(localized: "appicon.turtle",     defaultValue: "Turtle")
        case .hero:       return String(localized: "appicon.hero",       defaultValue: "Hero")
        }
    }
}

/// Applies the alternate icon that matches a logical option and the current appearance.
enum AppIconManager {
    /// `@AppStorage` key holding the user's logical icon choice (the source of truth).
    static let storageKey = "selectedAppIcon"

    static func apply(_ option: AppIconOption, for scheme: ColorScheme) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let target = option.iconName(for: scheme)
        // Skip redundant changes so iOS shows its "changed icon" alert only on a real swap.
        guard UIApplication.shared.alternateIconName != target else { return }
        UIApplication.shared.setAlternateIconName(target) { _ in }
    }
}

struct AppIconPickerView: View {
    @AppStorage(AppIconManager.storageKey) private var selectedRaw = AppIconOption.default.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private var selected: AppIconOption { AppIconOption(rawValue: selectedRaw) ?? .default }

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 16, alignment: .top),
        count: 3
    )

    var body: some View {
        ZStack {
            Material.Surface.tertiary
                .ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(AppIconOption.allCases) { option in
                        Button {
                            select(option)
                        } label: {
                            AppIconTile(option: option, isSelected: option == selected)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.displayName)
                        .accessibilityAddTraits(
                            option == selected ? [.isButton, .isSelected] : .isButton
                        )
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle(String(localized: "appicon.title", defaultValue: "App Icon"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Material.Surface.tertiary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func select(_ option: AppIconOption) {
        guard option != selected else { return }
        selectedRaw = option.rawValue
        Haptics.toggleOn()
        AppIconManager.apply(option, for: colorScheme)
    }
}

struct AppIconTile: View {
    let option: AppIconOption
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                Image(option.previewAssetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: Material.Shape.appIcon, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Material.Shape.appIcon, style: .continuous)
                            .strokeBorder(
                                isSelected ? Material.Text.accent : Material.Decoration.tertiary,
                                lineWidth: isSelected ? 3 : 1
                            )
                    )

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppFont.body)
                        .foregroundStyle(Material.Text.inverse, Material.Text.accent)
                        .background(Circle().fill(Material.Surface.tertiary))
                        .offset(x: 5, y: 5)
                }
            }

            Text(option.displayName)
                .font(AppFont.caption)
                .foregroundColor(isSelected ? Material.Text.primary : Material.Text.secondary)
        }
    }
}
