import SwiftUI

// ============================================================
// MARK: - UIColor Hex Init
// ============================================================

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red:   CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8)  & 0xFF) / 255,
            blue:  CGFloat( hex        & 0xFF) / 255,
            alpha: 1.0
        )
    }
}

// ============================================================
// MARK: - Raw Palette Ramps (50 = lightest, 950 = darkest)
// ============================================================

enum Palette {
    
    // MARK: Neutral — Cool Gray
    static let neutral0   = UIColor(hex: 0xFDFDFC) // #FDFDFC  ← step 100
    static let neutral25  = UIColor(hex: 0xFBFBFA) // #FBFBFA  ← step 99
    static let neutral50  = UIColor(hex: 0xF8F8F7) // #F8F8F7  ← step 98
    static let neutral100 = UIColor(hex: 0xEDEDEC) // #EDEDEC  ← step 95
    static let neutral150 = UIColor(hex: 0xE4E5E3) // #E4E5E3  ← step 92
    static let neutral200 = UIColor(hex: 0xDBDCDA) // #DBDCDA  ← step 90
    static let neutral300 = UIColor(hex: 0xBABCB9) // #BABCB9  ← step 80
    static let neutral400 = UIColor(hex: 0x979A96) // #979A96  ← step 70
    static let neutral500 = UIColor(hex: 0x5E6260) // #5E6260  ← step 50
    static let neutral600 = UIColor(hex: 0x3A3E3C) // #3A3E3C  ← step 35
    static let neutral700 = UIColor(hex: 0x262626) // #262626  ← step 25
    static let neutral800 = UIColor(hex: 0x1C1C1E) // #1C1C1E  ← step 15
    static let neutral900 = UIColor(hex: 0x191919) // #191919  ← step 10
    static let neutral950 = UIColor(hex: 0x000000) // #000000  ← step 5
    
    // MARK: Green
    static let green50  = UIColor(hex: 0xE4F5EA) // #E4F5EA  ← step 98
    static let green100 = UIColor(hex: 0xC8EDD5) // #C8EDD5  ← step 95
    static let green200 = UIColor(hex: 0x9EE0B8) // #9EE0B8  ← step 90
    static let green300 = UIColor(hex: 0x57CC8A) // #57CC8A  ← step 80
    static let green400 = UIColor(hex: 0x129E4E) // #129E4E  ← step 60
    static let green500 = UIColor(hex: 0x0D843E) // #0D843E  ← step 50
    static let green600 = UIColor(hex: 0x0A6A32) // #0A6A32  ← step 40
    static let green700 = UIColor(hex: 0x075026) // #075026  ← step 30
    static let green800 = UIColor(hex: 0x04371A) // #04371A  ← step 20
    static let green900 = UIColor(hex: 0x021D0E) // #021D0E  ← step 10
    static let green950 = UIColor(hex: 0x010F07) // #010F07  ← step 5
    
    // MARK: Blue — Periwinkle
    static let blue0   = UIColor(hex: 0xF5F8FB) // #F5F8FB  ← step 100
    static let blue25  = UIColor(hex: 0xEFF3F6) // #EFF3F6  ← step 99
    static let blue50  = UIColor(hex: 0xEEF1FB) // #EEF1FB  ← step 98
    static let blue100 = UIColor(hex: 0xDDE3F6) // #DDE3F6  ← step 95
    static let blue200 = UIColor(hex: 0xB6C7EB) // #B6C7EB  ← step 90
    static let blue300 = UIColor(hex: 0x96ACD8) // #96ACD8  ← step 80
    static let blue350 = UIColor(hex: 0x93B0C1) // #93B0C1  ← step 70
    static let blue400 = UIColor(hex: 0x7995A6) // #7995A6  ← step 60
    static let blue500 = UIColor(hex: 0x5F7B8C) // #5F7B8C  ← step 50
    static let blue600 = UIColor(hex: 0x466272) // #466272  ← step 40
    static let blue650 = UIColor(hex: 0x3A5666) // #3A5666 ← step 35
    static let blue700 = UIColor(hex: 0x2F4A5A) // #2F4A5A  ← step 30
    static let blue750 = UIColor(hex: 0x253748) // #253748  ← step 25
    static let blue800 = UIColor(hex: 0x1F3040) // #1F3040  ← step 20
    static let blue850 = UIColor(hex: 0x192937) // #192937  ← step 15
    static let blue900 = UIColor(hex: 0x13212D) // #13212D  ← step 10
    static let blue950 = UIColor(hex: 0x09141A) // #09141A  ← step 5
    static let blue975 = UIColor(hex: 0x030A0F) // #030A0F  ← step 0
    
    // MARK: Red
    static let red50  = UIColor(hex: 0xFCE4E1) // #FCE4E1  ← step 98
    static let red100 = UIColor(hex: 0xF9CBC5) // #F9CBC5  ← step 95
    static let red200 = UIColor(hex: 0xF3A9A1) // #F3A9A1  ← step 90
    static let red300 = UIColor(hex: 0xE46F66) // #E46F66  ← step 80
    static let red400 = UIColor(hex: 0xCF3328) // #CF3328  ← step 60
    static let red500 = UIColor(hex: 0xB42820) // #B42820  ← step 50
    static let red600 = UIColor(hex: 0x961E18) // #961E18  ← step 40
    static let red700 = UIColor(hex: 0xF74C16) // #F74C16  ← step 30
    static let red800 = UIColor(hex: 0xEB4613) // #EB4613  ← step 20
    static let red900 = UIColor(hex: 0xAF2F06) // #AF2F06  ← step 10
    static let red950 = UIColor(hex: 0x240404) // #240404  ← step 5
    
    // MARK: Yellow / Amber
    static let yellow100 = UIColor(hex: 0xFFEBBF) // #FFEBBF
    static let yellow200 = UIColor(hex: 0xFFE099) // #FFE099
    static let yellow300 = UIColor(hex: 0xFFD60A) // #FFD60A
    static let yellow400 = UIColor(hex: 0xFFCC00) // #FFCC00
    static let yellow600 = UIColor(hex: 0x4A2E12) // #4A2E12
    static let yellow700 = UIColor(hex: 0x35220E) // #35220E

    // MARK: Rose — muted warm pink (Card theme: Bloom, Dusk)
    static let rose25  = UIColor(hex: 0xFFF0EF) // #FFF0EF  ← step 99
    static let rose50  = UIColor(hex: 0xFFE4E2) // #FFE4E2  ← step 98
    static let rose100 = UIColor(hex: 0xFFCDCA) // #FFCDCA  ← step 95
    static let rose200 = UIColor(hex: 0xF5B8B4) // #F5B8B4  ← step 90
    static let rose700 = UIColor(hex: 0x5A2B29) // #5A2B29  ← step 30
    static let rose900 = UIColor(hex: 0x2E1211) // #2E1211  ← step 10
    static let rose950 = UIColor(hex: 0x1E0D0C) // #1E0D0C  ← step 5

    // MARK: Lavender — muted soft purple (Card theme: Bloom, Meadow)
    static let lavender25  = UIColor(hex: 0xF5F0FF) // #F5F0FF  ← step 99
    static let lavender50  = UIColor(hex: 0xEDE8FB) // #EDE8FB  ← step 98
    static let lavender100 = UIColor(hex: 0xDDD5F5) // #DDD5F5  ← step 95
    static let lavender200 = UIColor(hex: 0xC4B5E8) // #C4B5E8  ← step 90
    static let lavender700 = UIColor(hex: 0x3D2E6B) // #3D2E6B  ← step 30
    static let lavender900 = UIColor(hex: 0x241B42) // #241B42  ← step 10
    static let lavender950 = UIColor(hex: 0x130E22) // #130E22  ← step 5

    // MARK: Sage — muted warm green (Card theme: Meadow, Dusk)
    static let sage25  = UIColor(hex: 0xEEF5F0) // #EEF5F0  ← step 99
    static let sage50  = UIColor(hex: 0xE4F0E8) // #E4F0E8  ← step 98
    static let sage100 = UIColor(hex: 0xCCE5D4) // #CCE5D4  ← step 95
    static let sage200 = UIColor(hex: 0xA8D4B4) // #A8D4B4  ← step 90
    static let sage700 = UIColor(hex: 0x1E4A2C) // #1E4A2C  ← step 30
    static let sage900 = UIColor(hex: 0x0F2518) // #0F2518  ← step 10
    static let sage950 = UIColor(hex: 0x0A2014) // #0A2014  ← step 5

}

// ============================================================
// MARK: - Card Color Theme
// ============================================================

/// User-selectable card color palette. Each theme supplies one gradient
/// array per priority-card position (index 0, 1, 2). All stops stay in
/// the 25–200 light / 700–950 dark range to keep colors muted and legible.
enum CardColorTheme: String, CaseIterable {

    /// All-blue periwinkle — the original default.
    case standard
    /// Lavender · Rose · Blue — distinct hue per card position.
    case color

    var label: String {
        switch self {
        case .standard: return String(localized: "theme.standard", defaultValue: "Standard")
        case .color:    return String(localized: "theme.color",    defaultValue: "Color")
        }
    }

    /// Three gradient-stop arrays, one per card position (0 = top, 1, 2).
    var cardGradients: [[Color]] {
        switch self {
        case .standard:
            return [
                [adaptive(light: Palette.blue25,      dark: Palette.blue950),
                 adaptive(light: Palette.blue200,     dark: Palette.blue700)],
                [adaptive(light: Palette.blue50,      dark: Palette.blue900),
                 adaptive(light: Palette.blue200,     dark: Palette.blue700)],
                [adaptive(light: Palette.blue25,      dark: Palette.blue950),
                 adaptive(light: Palette.blue50,      dark: Palette.blue900),
                 adaptive(light: Palette.blue200,     dark: Palette.blue700)],
            ]
        case .color:
            return [
                [adaptive(light: Palette.lavender25,  dark: Palette.lavender950),
                 adaptive(light: Palette.lavender200, dark: Palette.lavender700)],
                [adaptive(light: Palette.rose25,      dark: Palette.rose950),
                 adaptive(light: Palette.rose200,     dark: Palette.rose700)],
                [adaptive(light: Palette.blue25,      dark: Palette.blue950),
                 adaptive(light: Palette.blue200,     dark: Palette.blue700)],
            ]
        }
    }

    /// Three representative mid-range colors, one per card position.
    var swatchColors: [Color] {
        switch self {
        case .standard:
            return [
                adaptive(light: Palette.blue200,     dark: Palette.blue700),
                adaptive(light: Palette.blue100,     dark: Palette.blue750),
                adaptive(light: Palette.blue50,      dark: Palette.blue900),
            ]
        case .color:
            return [
                adaptive(light: Palette.lavender200, dark: Palette.lavender700),
                adaptive(light: Palette.rose200,     dark: Palette.rose700),
                adaptive(light: Palette.blue200,     dark: Palette.blue700),
            ]
        }
    }
}

// ============================================================
// MARK: - Adaptive Color Helper
// ============================================================

fileprivate func adaptive(light: UIColor, dark: UIColor) -> Color {
    Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
}

// ============================================================
// MARK: - Material System (single source of truth)
// ============================================================

enum Material {
    
    // MARK: Surface — neutral backgrounds
    // backdrop → primary → secondary → tertiary (canvas → content → elevated → inset)
    
    enum Surface {
        static let backdrop  = adaptive(light: Palette.neutral25,  dark: Palette.neutral950)   // app canvas (root ZStack)
        static let primary   = adaptive(light: Palette.neutral50, dark: Palette.neutral900)    // pages: note editor, settings, text editor (UIKit)
        static let secondary = adaptive(light: Palette.neutral100,  dark: Palette.neutral800)    // elevated panels: drawer, sheets, toast, analytics cards, mic chip fill
        static let tertiary  = backdrop     // page background: NotePage, Settings, WidgetInstructions, DevComponents
        static let primaryUIColor: UIColor = UIColor { $0.userInterfaceStyle == .dark ? Palette.neutral700 : Palette.neutral150 }
        static let secondaryUIColor: UIColor = UIColor { $0.userInterfaceStyle == .dark ? Palette.neutral150 : Palette.neutral700 }
    }
    
    // MARK: Control — interactive fill (Blue)
    // Buttons, chips, pickers, inputs, card gradients
    
    enum Control {
        static let fillPrimary   = adaptive(light: Palette.neutral150, dark: Palette.neutral700)  // FilledButtonStyle, ChipPicker selected, Card.base/wrapper gradient
        static let fillSecondary = adaptive(light: Palette.neutral0,  dark: Palette.neutral950)  // Card.base/onboarding/widget gradients
        static let fillTertiary  = adaptive(light: Palette.neutral50,  dark: Palette.neutral800)  // mic/plus ActionChips, feedback input, drawer cards, ChipPicker unselected, ListSuggestion, Card.onboarding/widget gradients
    }
    
    // MARK: Text — text foreground colors
    
    enum Text {
        static let primary   = adaptive(light: Palette.neutral950, dark: Palette.neutral50)  // headings, body copy, card text, button labels, chip icon overrides, widget text/button
        static let secondary = adaptive(light: Palette.neutral700, dark: Palette.neutral200) // supporting labels, captions, hints, settings descriptions, debug rows, GhostButtonStyle, widget muted text
        static let tertiary  = adaptive(light: Palette.neutral400, dark: Palette.neutral500) // subtle: action chip icon on neutral fills, SolidButtonStyle disabled label, widget button text
        static let accent    = Accent.primary                                                // settings tint: app icon fill, picker, primary button bg
        static let inverse   = adaptive(light: Palette.neutral50, dark: Palette.neutral950)                                     // text on dark/accent fills: SolidButtonStyle label, settings buttons, slider tint
    }
    
    // MARK: Icon — icon foreground colors
    
    enum Icon {
        static let primary   = adaptive(light: Palette.neutral950, dark: Palette.neutral50)  // settings tortoise icon, CloseButton xmark, success chip icon
        static let tertiary  = adaptive(light: Palette.neutral700, dark: Palette.neutral500) // delete action chip icon (trash)
        static let inverse   = Color(Palette.neutral50)                                      // default ActionChip icon on colored fills
        static let muted     = adaptive(light: Palette.neutral600, dark: Palette.neutral400) // empty-state icons, secondary toolbar icons
    }
    
    // MARK: Typography — size scale (consumed by AppFont)
    
    enum Typography {
        static let title:   CGFloat = 40   // AppFont.title
        static let priority: CGFloat = 20   // AppFont.priority — priority card body text
        static let headline: CGFloat = 22  // AppFont.headline
        static let icon:    CGFloat = 20   // AppFont.icon
        static let body:    CGFloat = 17   // AppFont.body, AppFont.bodyUIFont
        static let subhead: CGFloat = 14   // AppFont.subhead — widget large secondary rows
        static let label:   CGFloat = 13   // AppFont.label
        static let caption: CGFloat = 12   // AppFont.caption, widget medium secondary rows
        static let micro:   CGFloat = 10   // AppFont.micro
        
        static let widgetHero:      CGFloat = 28  // AppFont.widgetHero — medium widget rank-0
        static let widgetLargeHero: CGFloat = 24  // AppFont.widgetLargeHero — large widget rank-0
        
        enum Tracking {
            static let widgetHero:      CGFloat = -0.84   // medium widget rank-0
            static let widgetLargeHero: CGFloat = -0.72   // large widget rank-0
            static let widgetCompact:   CGFloat = -0.60   // compact widget hero
            static let widgetSecondary: CGFloat = -0.168  // large widget rank-1+
            static let widgetLabel:     CGFloat = -0.156  // widget empty labels
            static let widgetCaption:   CGFloat = -0.144  // medium widget rank-1+
            static let widgetButton:    CGFloat = -0.13   // widget note button
        }
    }
    
    // MARK: Accent — brand color (light: red, dark: green)
    
    enum Accent {
        static let primary     = adaptive(light: Palette.red800,  dark: Palette.red700)     // ActionChip.accent icon, Text.accent, Card.accent, settings tint
        static let contentPrimary   = adaptive(light: Palette.neutral0,  dark: Palette.neutral950) // text/icon on accent fill (SolidButtonStyle)
    }
    
    // MARK: Decoration — neutral ornaments (borders, dividers, shapes)
    
    enum Decoration {
        static let primary   = adaptive(light: Palette.neutral600, dark: Palette.neutral200) // swipe action chip fills: trash, dismiss (xmark)
        static let tertiary  = adaptive(light: Palette.neutral200, dark: Palette.neutral600) // settings card border, sign-out stroke
    }
    
    // MARK: Shape — radii & sizing (4pt grid)
    
    enum Shape {
        // Base scale (only values referenced directly in views)
        static let x2: CGFloat = 8
        static let x3: CGFloat = 12
        static let full: CGFloat = 9999
        
        // Semantic radii
        static let card: CGFloat = 30
        static let chip: CGFloat = full
        static let drawer: CGFloat = 32
        static let input: CGFloat = 12
        static let control: CGFloat = 12
        static let handle: CGFloat = 8
        static let appIcon: CGFloat = 14
        
        // Component sizing (diameter)
        static let chipLarge: CGFloat = 60
        static let chipMedium: CGFloat = 48
        static let chipSmall: CGFloat = 44
    }
    
    // MARK: Elevation — shadow & overlay
    
    enum Elevation {
        static let shadow    = adaptive(light: Palette.neutral200, dark: Palette.neutral950) // CardSurface, CloseButton, toast, toolbar buttons, settings cards, widget capsule
        static let scrim     = adaptive(light: Palette.neutral800, dark: Palette.neutral800) // drawer drag handle track fill
    }
    
    // MARK: Status — semantic colored signals
    
    enum Status {
        static let success = adaptive(light: Palette.green200, dark: Palette.green100) // complete action chip, settings app icon previews (Messages, Phone)
        static let warning = adaptive(light: Palette.yellow400, dark: Palette.yellow300) // priority action chip, Card.boost gradient
        static let error   = adaptive(light: Palette.red300,   dark: Palette.red100)   // settings app icon preview (Photos)
        static let info    = adaptive(light: Palette.blue300,   dark: Palette.blue500)  // archive action chip, settings gradient, Card.wrapper gradient, debug emphasis
    }
    
    // MARK: Card — gradient arrays
    
    enum Card {
        static let gradients: [[Color]] = [
            [Control.fillTertiary, Control.fillPrimary],                        // white-blue → cornflower
            [Control.fillSecondary, Control.fillPrimary],                       // lavender → cornflower
            [Control.fillTertiary, Control.fillSecondary, Control.fillPrimary], // smoother three-stop sweep
        ]

        // MARK: Priority card fills — flat neutral surface for all positions
        private static let priorityFills: [[Color]] = [
            [adaptive(light: Palette.neutral0, dark: Palette.neutral950)],
            [adaptive(light: Palette.neutral50, dark: Palette.neutral900)],
            [adaptive(light: Palette.neutral100, dark: Palette.neutral800)],
        ]

        static func colors(for index: Int) -> [Color] {
            priorityFills[index % priorityFills.count]
        }

        // MARK: Priority card border
        static let border: Color      = adaptive(light: Palette.neutral150, dark: Palette.neutral700)
        static let borderWidth: CGFloat = 2

        static let base:       [Color] = gradients[0]                                                  // fallback for generic/preview usage
        static let onboarding: [Color] = [Control.fillTertiary,  Control.fillPrimary]                // onboarding card variant
        static let boost:      [Color] = [Status.warning.opacity(0.25), Status.warning.opacity(0.45)]  // CardBoost inner gradient
        static let wrapper:    [Color] = [Control.fillPrimary,   Status.info]                          // CardBoost outer wrapper gradient
        static let accent              =  Accent.primary                                               // boost "Limitless" label & bolt icon
    }
    
}


// ============================================================
// MARK: - Text Style Tokens
// ============================================================

enum AppFont {
    static let title    = Font.system(size: Material.Typography.title, weight: .bold, design: .rounded)
    static let priority = Font.system(size: Material.Typography.priority, weight: .regular)
    static let headline = Font.system(size: Material.Typography.headline, weight: .bold, design: .rounded)
    static let icon     = Font.system(size: Material.Typography.icon, weight: .bold)
    static let body     = Font.system(size: Material.Typography.body, weight: .regular)
    static let bodyMono = Font.system(size: Material.Typography.body, weight: .regular).monospacedDigit()
    static let subhead  = Font.system(size: Material.Typography.subhead, weight: .regular)
    static let label    = Font.system(size: Material.Typography.label, weight: .medium)
    static let caption  = Font.system(size: Material.Typography.caption, weight: .regular)
    static let micro    = Font.system(size: Material.Typography.micro, weight: .regular)
    
    static let widgetHero      = Font.system(size: Material.Typography.widgetHero, weight: .heavy)
    static let widgetLargeHero = Font.system(size: Material.Typography.widgetLargeHero, weight: .heavy)
    
    static let bodyUIFont = UIFont.systemFont(ofSize: Material.Typography.body)
}

// ============================================================
// MARK: - Button Styles
// ============================================================

private struct PressEffect: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isPressed ? 0.75 : 1)
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: isPressed)
    }
}

struct SolidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body).fontWeight(.semibold)
            .foregroundColor(Material.Accent.contentPrimary)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(Material.Accent.primary)
            .clipShape(Capsule())
            .modifier(PressEffect(isPressed: configuration.isPressed))
    }
}

struct FilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body).fontWeight(.medium)
            .foregroundColor(Material.Text.primary)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(Material.Control.fillSecondary)
            .clipShape(Capsule())
            .modifier(PressEffect(isPressed: configuration.isPressed))
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body).fontWeight(.medium)
            .foregroundColor(Material.Text.secondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .opacity(configuration.isPressed ? 0.4 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SolidButtonStyle {
    static var solid: SolidButtonStyle { .init() }
}

extension ButtonStyle where Self == FilledButtonStyle {
    static var filled: FilledButtonStyle { .init() }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { .init() }
}

struct GlassButtonStyle: ButtonStyle {
    let tint: Color
    var foreground: Color = Material.Text.primary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    tint
                    Color.clear.background(.thinMaterial)
                }
            )
            .overlay(Capsule().stroke(tint.opacity(0.3), lineWidth: 1.5))
            .shadow(color: tint.opacity(0.4), radius: 8, x: 0, y: 4)
            .clipShape(Capsule())
            .modifier(PressEffect(isPressed: configuration.isPressed))
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static func glass(tint: Color, foreground: Color = Material.Text.primary) -> GlassButtonStyle {
        .init(tint: tint, foreground: foreground)
    }
}

#Preview("Button Styles") {
    VStack(spacing: 20) {
        Button {
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Note")
            }
        }
        .buttonStyle(.solid)
        
        Button {
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                Text("Record")
            }
        }
        .buttonStyle(.filled)
        
        Button("Cancel") {}
            .buttonStyle(.ghost)
    }
    .padding(24)
    .background(Material.Surface.primary)
}

// ============================================================
// MARK: - Toast
// ============================================================

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: LocalizedStringKey
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            
            if isPresented {
                Text(message)
                    .font(AppFont.body)
                    .foregroundColor(Material.Text.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Material.Surface.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: Material.Shape.input))
                    .shadow(color: Material.Elevation.shadow.opacity(0.15), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: LocalizedStringKey) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message))
    }
}

// ============================================================
// MARK: - Noise Background
// ============================================================

struct NoiseConfig {
    enum NoiseType { case random, grain, staticNoise }
    enum GradientShape { case linear, easeIn, easeOut, sCurve }

    var noiseType: NoiseType         = .grain
    var topOpacity: Double           = 0.0
    var bottomOpacity: Double        = 0.15
    var gradientShape: GradientShape = .sCurve
    var tintColor: Color             = .white   // white = no tint (multiply identity)
    var noiseSize: CGFloat           = 50

    // Light mode: coarse dark grain
    static let `default` = NoiseConfig(
        noiseType: .grain,
        topOpacity: 0.0,
        bottomOpacity: 0.30,
        gradientShape: .sCurve,
        tintColor: Color(uiColor: Palette.neutral950),
        noiseSize: 50
    )

    // Dark mode: finer light grain
    static let defaultDark = NoiseConfig(
        noiseType: .grain,
        topOpacity: 0.0,
        bottomOpacity: 0.20,
        gradientShape: .sCurve,
        tintColor: Color(uiColor: Palette.neutral0),
        noiseSize: 100
    )
}

struct NoisyBackgroundView: View {
    let config: NoiseConfig
    let scrollOffset: CGFloat

    private static let noiseImages: [NoiseConfig.NoiseType: UIImage] = makeAllNoise()

    var body: some View {
        ZStack {
            Material.Surface.backdrop.ignoresSafeArea()
            if let img = Self.noiseImages[config.noiseType] {
                Canvas { ctx, size in
                    let tile = CGSize(width: config.noiseSize, height: config.noiseSize)
                    let resolved = ctx.resolve(Image(uiImage: img))
                    var y: CGFloat = 0
                    while y < size.height {
                        var x: CGFloat = 0
                        while x < size.width {
                            ctx.draw(resolved, in: CGRect(origin: CGPoint(x: x, y: y), size: tile))
                            x += tile.width
                        }
                        y += tile.height
                    }
                }
                .colorMultiply(config.tintColor)
                .blendMode(.overlay)
                .mask(noiseMask)
                .ignoresSafeArea()
            }
        }
    }

    private var noiseMask: some View {
        let scrollShift = Double(scrollOffset) / 600.0
        let stops = gradientStops(
            top: config.topOpacity,
            bottom: config.bottomOpacity,
            shape: config.gradientShape,
            scrollShift: scrollShift
        )
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }

    private func gradientStops(top: Double, bottom: Double,
                                shape: NoiseConfig.GradientShape,
                                scrollShift: Double) -> [Gradient.Stop] {
        let anchor = max(0.0, 0.35 - scrollShift)
        switch shape {
        case .linear:
            return [
                .init(color: .black.opacity(top), location: 0),
                .init(color: .black.opacity(bottom), location: 1)
            ]
        case .easeIn:
            return [
                .init(color: .black.opacity(top), location: 0),
                .init(color: .black.opacity(top), location: anchor),
                .init(color: .black.opacity(bottom), location: 1)
            ]
        case .easeOut:
            return [
                .init(color: .black.opacity(top), location: 0),
                .init(color: .black.opacity(bottom * 0.6), location: anchor),
                .init(color: .black.opacity(bottom), location: 1)
            ]
        case .sCurve:
            let mid = (anchor + 1) / 2
            return [
                .init(color: .black.opacity(top), location: 0),
                .init(color: .black.opacity(top), location: anchor),
                .init(color: .black.opacity(bottom * 0.5), location: mid),
                .init(color: .black.opacity(bottom), location: 1)
            ]
        }
    }

    private static func makeAllNoise() -> [NoiseConfig.NoiseType: UIImage] {
        var result: [NoiseConfig.NoiseType: UIImage] = [:]
        let size = CGSize(width: 250, height: 250)
        let ctx = CIContext()
        guard let filter = CIFilter(name: "CIRandomGenerator"),
              let output = filter.outputImage else { return result }
        let cropped = output.cropped(to: CGRect(origin: .zero, size: size))

        if let cg = ctx.createCGImage(cropped, from: cropped.extent) {
            result[.random] = UIImage(cgImage: cg)
        }
        if let desaturated = CIFilter(name: "CIColorControls", parameters: [
               kCIInputImageKey: cropped,
               kCIInputSaturationKey: 0.0 as NSNumber
           ]),
           let blurred = CIFilter(name: "CIGaussianBlur", parameters: [
               kCIInputImageKey: desaturated.outputImage!,
               kCIInputRadiusKey: 0.5 as NSNumber
           ]),
           let cg = ctx.createCGImage(blurred.outputImage!, from: cropped.extent) {
            result[.grain] = UIImage(cgImage: cg)
        }
        if let posterized = CIFilter(name: "CIColorPosterize", parameters: [
               kCIInputImageKey: cropped,
               "inputLevels": 2 as NSNumber
           ]),
           let cg = ctx.createCGImage(posterized.outputImage!, from: cropped.extent) {
            result[.staticNoise] = UIImage(cgImage: cg)
        }
        return result
    }
}

// ============================================================
// MARK: - List Suggestion Row
// ============================================================

struct ListSuggestion: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(AppFont.body)
                    .foregroundColor(Material.Text.primary)
                Spacer()
                Image(systemName: "arrow.up.left")
                    .font(AppFont.caption)
                    .foregroundColor(Material.Text.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Material.Control.fillTertiary)
            .clipShape(RoundedRectangle(cornerRadius: Material.Shape.control))
        }
    }
}

