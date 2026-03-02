import SwiftUI

// MARK: - Card Variant
enum CardVariant: Equatable {
    case cardDefault
    case cardOnboarding
    case cardBoost
    case cardDrawer  // Plain style for drawer cards
    
    var gradientColors: [Color] {
        switch self {
        case .cardDefault:
            return [
                Color(red: 0xC4/255, green: 0xD5/255, blue: 0xF7/255),   // 0% - #C4D5F7
                Color(red: 0xE7/255, green: 0xED/255, blue: 0xF9/255),   // 33% - #E7EDF9
                Color(red: 0xCC/255, green: 0xDA/255, blue: 0xF7/255),   // 64% - #CCDAF7
                Color(red: 0x60/255, green: 0x90/255, blue: 0xEA/255)    // 100% - #6090EA
            ]
        case .cardOnboarding:
            return [
                Color(red: 0.92, green: 0.92, blue: 0.98),  // Very light lavender top
                Color(red: 0.88, green: 0.88, blue: 0.96)   // Light lavender bottom
            ]
        case .cardBoost:
            // Inner card gradient (orange/yellow)
            return [
                Color(red: 1.0, green: 0.92, blue: 0.75),   // Light orange/peach top
                Color(red: 0.98, green: 0.80, blue: 0.60)   // Deeper orange/gold bottom
            ]
        case .cardDrawer:
            // Plain color for drawer cards - #F2F2F7
            return [
                Color(red: 0xF2/255, green: 0xF2/255, blue: 0xF7/255)
            ]
        }
    }
    
    var textColor: Color {
        return .black.opacity(0.85)
    }
    
    var hasShadow: Bool {
        switch self {
        case .cardDrawer:
            return false  // No shadow for drawer cards
        default:
            return true
        }
    }
}

// MARK: - Card Component (Default & Onboarding)
struct CardComponent: View {
    let text: String
    var variant: CardVariant = .cardDefault
    var minHeight: CGFloat? = nil
    var cornerRadius: CGFloat = 35
    var fontSize: CGFloat = 18
    var horizontalPadding: CGFloat = 25
    var verticalPadding: CGFloat = 20
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .regular))
            .foregroundColor(variant.textColor)
            .multilineTextAlignment(.leading)
            .lineLimit(6)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: minHeight)
            .background(
                Group {
                    if variant == .cardDefault {
                        // Add subtle randomization to gradient for visual variety
                        let variation = Double.random(in: -0.05...0.05)
                        let angleVariation = Double.random(in: -0.1...0.1)
                        
                        return AnyView(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: variant.gradientColors[0], location: max(0, 0.0 + variation)),
                                    .init(color: variant.gradientColors[1], location: max(0.1, min(0.4, 0.33 + variation))),
                                    .init(color: variant.gradientColors[2], location: max(0.5, min(0.75, 0.64 + variation))),
                                    .init(color: variant.gradientColors[3], location: 1.0)
                                ]),
                                startPoint: UnitPoint(x: angleVariation, y: angleVariation),
                                endPoint: UnitPoint(x: 1.0 + angleVariation, y: 1.0 + angleVariation)
                            )
                        )
                    } else if variant == .cardDrawer {
                        // Plain solid color for drawer cards
                        return AnyView(
                            variant.gradientColors[0]
                        )
                    } else {
                        return AnyView(
                            LinearGradient(
                                colors: variant.gradientColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            )
            .cornerRadius(cornerRadius)
            .shadow(
                color: variant.hasShadow ? .black.opacity(0.09) : .clear,
                radius: variant.hasShadow ? 3 : 0,
                x: 0,
                y: variant.hasShadow ? 3 : 0
            )
    }
}

// MARK: - Card Onboarding Component
struct CardOnboarding: View {
    var minHeight: CGFloat? = nil
    var cornerRadius: CGFloat = 35
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Capture anything that's in your mind. Like a dream, idea or to-do. ")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.black.opacity(0.85))
            + Text("Simple.")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black.opacity(0.85))
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
        .frame(minHeight: minHeight)
        .background(
            LinearGradient(
                colors: CardVariant.cardOnboarding.gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(cornerRadius)
        .shadow(color: .black.opacity(0.09), radius: 3, x: 0, y: 3)
    }
}

// MARK: - Card Boost Component
struct CardBoost: View {
    let text: String
    var label: String = "Limitless"
    var minHeight: CGFloat? = nil
    var outerCornerRadius: CGFloat = 35
    var innerCornerRadius: CGFloat = 28
    
    // Pink/purple wrapper gradient
    private let wrapperGradient = [
        Color(red: 0.95, green: 0.80, blue: 0.92),  // Light pink top
        Color(red: 0.90, green: 0.75, blue: 0.90)   // Deeper pink/purple bottom
    ]
    
    // Purple accent color for label and icon
    private let accentColor = Color(red: 0.45, green: 0.25, blue: 0.70)
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with label and icon
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accentColor)
                
                Spacer()
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Inner card with orange/yellow gradient
            Text(text)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.black.opacity(0.85))
                .multilineTextAlignment(.leading)
                .lineLimit(6)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: CardVariant.cardBoost.gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(innerCornerRadius)
        }
        .frame(minHeight: minHeight)
        .background(
            LinearGradient(
                colors: wrapperGradient,
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(outerCornerRadius)
        .shadow(color: .black.opacity(0.09), radius: 3, x: 0, y: 3)
    }
}

// MARK: - Previews
#Preview("Card Variants") {
    ScrollView {
        VStack(spacing: 20) {
            Text("card-default")
                .font(.caption)
                .foregroundColor(.secondary)
            CardComponent(
                text: "Test example of something to do.",
                variant: .cardDefault,
                minHeight: 200
            )
            
            Text("card-drawer")
                .font(.caption)
                .foregroundColor(.secondary)
            CardComponent(
                text: "This is a drawer card with plain background.",
                variant: .cardDrawer,
                minHeight: 100
            )
            
            Text("card-onboarding")
                .font(.caption)
                .foregroundColor(.secondary)
            CardOnboarding(minHeight: 150)
            
            Text("card-boost")
                .font(.caption)
                .foregroundColor(.secondary)
            CardBoost(
                text: "Test example of something to do.",
                minHeight: 250
            )
        }
        .padding()
    }
}
