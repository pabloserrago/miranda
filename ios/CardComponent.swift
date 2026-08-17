import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - Card Surface Modifier

struct CardSurface: ViewModifier {
    let colors: [Color]
    var radius: CGFloat
    var shadow: Bool
    var gradientStart: UnitPoint
    var gradientEnd: UnitPoint
    var borderColor: Color
    var borderWidth: CGFloat
    var glass: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if glass, #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius))
                .overlay(
                    Group {
                        if borderWidth > 0 {
                            RoundedRectangle(cornerRadius: radius)
                                .stroke(borderColor.opacity(0.4), lineWidth: 1)
                        }
                    }
                )
        } else {
            content
                .background(
                    Group {
                        if colors.count == 1 {
                            colors[0]
                        } else {
                            LinearGradient(colors: colors, startPoint: gradientStart, endPoint: gradientEnd)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: radius))
                .overlay(
                    Group {
                        if borderWidth > 0 {
                            RoundedRectangle(cornerRadius: radius)
                                .stroke(borderColor, lineWidth: borderWidth)
                        }
                    }
                )
                .shadow(
                    color: shadow ? Material.Elevation.shadow.opacity(0.09) : .clear,
                    radius: shadow ? 3 : 0,
                    x: 0,
                    y: shadow ? 3 : 0
                )
        }
    }
}

extension View {
    func cardSurface(
        _ colors: [Color],
        radius: CGFloat = Material.Shape.card,
        shadow: Bool = true,
        from: UnitPoint = .topLeading,
        to: UnitPoint = .bottomTrailing,
        borderColor: Color = .clear,
        borderWidth: CGFloat = 0,
        glass: Bool = true
    ) -> some View {
        modifier(CardSurface(
            colors: colors,
            radius: radius,
            shadow: shadow,
            gradientStart: from,
            gradientEnd: to,
            borderColor: borderColor,
            borderWidth: borderWidth,
            glass: glass
        ))
    }
}

// MARK: - Card Variant

enum CardVariant: Equatable {
    case cardDefault
    case cardOnboarding
    case cardBoost
    case cardDrawer
    
    var colors: [Color] {
        switch self {
        case .cardDefault:    return Material.Card.base
        case .cardOnboarding: return Material.Card.onboarding
        case .cardBoost:      return Material.Card.boost
        case .cardDrawer:     return [Material.Control.fillTertiary]
        }
    }
    
    var hasShadow: Bool {
        self != .cardDrawer
    }
}

// MARK: - Card Component

struct CardComponent: View {
    let text: String
    var variant: CardVariant = .cardDefault
    var minHeight: CGFloat? = nil
    var horizontalPadding: CGFloat = 25
    var verticalPadding: CGFloat = 20
    
    var body: some View {
        Text(text)
            .font(AppFont.body)
            .foregroundColor(Material.Text.primary)
            .multilineTextAlignment(.leading)
            .lineLimit(6)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: minHeight)
            .cardSurface(variant.colors, shadow: variant.hasShadow)
    }
}

// MARK: - Card Onboarding Component

struct CardOnboarding: View {
    var minHeight: CGFloat? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Capture anything that's in your mind. Like a dream, idea or to-do. ")
                .font(AppFont.body)
                .foregroundColor(Material.Text.primary)
            + Text("Simple.")
                .font(AppFont.body).bold()
                .foregroundColor(Material.Text.primary)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
        .frame(minHeight: minHeight)
        .cardSurface(Material.Card.onboarding, from: .top, to: .bottom)
    }
}

// MARK: - Widget Preview
// App-target only (references AppIcon from SettingsView); must not live in
// StyleTokens.swift, which is compiled into the widget extension.

/// Mockup of an iPhone home screen with the Miranda widget showing `card`
/// (falls back to a placeholder). Used in Settings and onboarding step 2.
struct WidgetPreview: View {
    let card: Card?

    var body: some View {
        VStack(spacing: 20) {
            // Status bar area
            HStack {
                Text(verbatim: "9:41")
                    .font(AppFont.caption).fontWeight(.semibold)
                    .foregroundColor(Material.Text.primary.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            // Miranda widget (larger card)
            VStack(spacing: 0) {
                Text(card?.simplifiedText ?? String(localized: "Your priority"))
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
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        // Wallpaper as .background so its scaledToFill overflow doesn't
        // inflate the layout width (which pushed the preview off-center);
        // the cornerRadius clip below trims the overflow.
        .background(
            Image("BackgroundWidget")
                .resizable()
                .scaledToFill()
        )
        .cornerRadius(Material.Shape.drawer)
        .overlay(
            RoundedRectangle(cornerRadius: Material.Shape.drawer)
                .stroke(Material.Decoration.tertiary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Background Theme Picker
// App-target only (references Haptics); see WidgetPreview note above.

/// Row of swatch circles bound to the persisted background theme.
/// Used in Settings (Personalize) and onboarding step 3.
struct BackgroundThemePicker: View {
    @AppStorage(SharedCardManager.backgroundThemeKey, store: SharedCardManager.defaults)
    private var backgroundThemeRaw: String = BackgroundTheme.standard.rawValue
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        HStack(spacing: 10) {
            ForEach(BackgroundTheme.allCases, id: \.rawValue) { theme in
                Button {
                    guard backgroundThemeRaw != theme.rawValue else { return }
                    backgroundThemeRaw = theme.rawValue
                    Haptics.toggleOn()
                    #if canImport(WidgetKit)
                    WidgetKit.WidgetCenter.shared.reloadAllTimelines()
                    #endif
                } label: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.swatchColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle().stroke(
                                backgroundThemeRaw == theme.rawValue
                                    ? Material.Text.accent
                                    : Material.Decoration.tertiary,
                                lineWidth: backgroundThemeRaw == theme.rawValue ? 2 : 1
                            )
                        )
                        .overlay {
                            // The accent ring is the only colour cue for which
                            // swatch is chosen, so add a shape when the user has
                            // asked not to rely on colour. The glyph carries its
                            // own fill, keeping it legible on any swatch.
                            if differentiateWithoutColor, backgroundThemeRaw == theme.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Material.Text.inverse, Material.Text.primary)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(theme.label)
                .accessibilityAddTraits(
                    backgroundThemeRaw == theme.rawValue ? [.isButton, .isSelected] : .isButton
                )
            }
        }
    }
}

// MARK: - Card Boost Component

struct CardBoost: View {
    let text: String
    var label: String = "Limitless"
    var minHeight: CGFloat? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(AppFont.body).bold()
                    .foregroundColor(Material.Card.accent)
                
                Spacer()
                
                Image(systemName: "bolt.fill")
                    .font(AppFont.body).bold()
                    .foregroundColor(Material.Card.accent)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Text(text)
                .font(AppFont.body)
                .foregroundColor(Material.Text.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .cardSurface(Material.Card.boost, radius: Material.Shape.card, shadow: false, from: .top, to: .bottom)
        }
        .frame(minHeight: minHeight)
        .cardSurface(Material.Card.wrapper, from: .top, to: .bottom)
    }
}

// MARK: - Previews

#Preview("Card Variants") {
    ScrollView {
        VStack(spacing: 20) {
            Text("card-default")
                .font(AppFont.caption)
                .foregroundColor(Material.Text.secondary)
            CardComponent(
                text: "Test example of something to do.",
                variant: .cardDefault,
                minHeight: 200
            )
            
            Text("card-drawer")
                .font(AppFont.caption)
                .foregroundColor(Material.Text.secondary)
            CardComponent(
                text: "This is a drawer card with plain background.",
                variant: .cardDrawer,
                minHeight: 100
            )
            
            Text("card-onboarding")
                .font(AppFont.caption)
                .foregroundColor(Material.Text.secondary)
            CardOnboarding(minHeight: 150)
            
            Text("card-boost")
                .font(AppFont.caption)
                .foregroundColor(Material.Text.secondary)
            CardBoost(
                text: "Test example of something to do.",
                minHeight: 250
            )
        }
        .padding()
    }
}
