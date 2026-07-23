import SwiftUI

// MARK: - Card Surface Modifier

struct CardSurface: ViewModifier {
    let colors: [Color]
    var radius: CGFloat
    var shadow: Bool
    var gradientStart: UnitPoint
    var gradientEnd: UnitPoint
    var borderColor: Color
    var borderWidth: CGFloat

    func body(content: Content) -> some View {
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

extension View {
    func cardSurface(
        _ colors: [Color],
        radius: CGFloat = Material.Shape.card,
        shadow: Bool = true,
        from: UnitPoint = .topLeading,
        to: UnitPoint = .bottomTrailing,
        borderColor: Color = .clear,
        borderWidth: CGFloat = 0
    ) -> some View {
        modifier(CardSurface(
            colors: colors,
            radius: radius,
            shadow: shadow,
            gradientStart: from,
            gradientEnd: to,
            borderColor: borderColor,
            borderWidth: borderWidth
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
