import SwiftUI

// ============================================================
// MARK: - Palette (raw color values, defined once)
// ============================================================

enum Palette {

    // Neutrals
    static let white   = UIColor(white: 1.0, alpha: 1.0)
    static let black   = UIColor(white: 0.0, alpha: 1.0)
    static let black85 = UIColor(white: 0.0, alpha: 0.85)
    static let black60 = UIColor(white: 0.0, alpha: 0.60)
    static let black45 = UIColor(white: 0.0, alpha: 0.45)
    static let black10 = UIColor(white: 0.0, alpha: 0.10)

    // Green (actions)
    static let green      = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0)
    static let greenLight = UIColor(red: 0.30, green: 0.85, blue: 0.40, alpha: 1.0)

    // Green (text accent — darker for readability)
    static let greenText      = UIColor(red: 0.20, green: 0.65, blue: 0.25, alpha: 1.0)
    static let greenTextLight = UIColor(red: 0.40, green: 0.85, blue: 0.45, alpha: 1.0)

    // Yellow
    static let yellow      = UIColor(red: 1.0, green: 0.80, blue: 0.0, alpha: 1.0)
    static let yellowLight = UIColor(red: 1.0, green: 0.84, blue: 0.04, alpha: 1.0)

    // Red & Blue
    static let red      = UIColor(red: 0.90, green: 0.22, blue: 0.21, alpha: 1.0)
    static let redLight = UIColor(red: 1.0, green: 0.35, blue: 0.37, alpha: 1.0)
    static let blue      = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
    static let blueHigh = UIColor(red: 0.25, green: 0.61, blue: 1.0, alpha: 1.0)

    // ---- Light mode gradients ----

    // Card Default (pastel blue)
    static let blueLight = UIColor(red: 0xCC/255, green: 0xDA/255, blue: 0xF7/255, alpha: 1.0)
    static let bluePale  = UIColor(red: 0xE7/255, green: 0xED/255, blue: 0xF9/255, alpha: 1.0)
    static let blueMid   = UIColor(red: 0x60/255, green: 0x90/255, blue: 0xEA/255, alpha: 1.0)

    // Onboarding (lavender)
    static let lavenderLight = UIColor(red: 0.92, green: 0.92, blue: 0.98, alpha: 1.0)
    static let lavenderMid   = UIColor(red: 0.88, green: 0.88, blue: 0.96, alpha: 1.0)

    // Boost (peach)
    static let peachLight = UIColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0)
    static let peachMid   = UIColor(red: 0.98, green: 0.80, blue: 0.60, alpha: 1.0)

    // Boost wrapper (pink)
    static let pinkLight = UIColor(red: 0.95, green: 0.80, blue: 0.92, alpha: 1.0)
    static let pinkMid   = UIColor(red: 0.90, green: 0.75, blue: 0.90, alpha: 1.0)
    static let purple    = UIColor(red: 0.45, green: 0.25, blue: 0.70, alpha: 1.0)

    // ---- Dark mode gradients ----

    // Card Default (deep navy)
    static let navyDeep   = UIColor(red: 0x1A/255, green: 0x25/255, blue: 0x40/255, alpha: 1.0)
    static let navyMid    = UIColor(red: 0x1F/255, green: 0x2D/255, blue: 0x4A/255, alpha: 1.0)
    static let navyBright = UIColor(red: 0x2D/255, green: 0x45/255, blue: 0x70/255, alpha: 1.0)

    // Onboarding (deep violet)
    static let violetDeep = UIColor(red: 0x20/255, green: 0x1C/255, blue: 0x30/255, alpha: 1.0)
    static let violetMid  = UIColor(red: 0x2D/255, green: 0x26/255, blue: 0x42/255, alpha: 1.0)

    // Boost (deep amber)
    static let amberDeep = UIColor(red: 0x35/255, green: 0x22/255, blue: 0x0E/255, alpha: 1.0)
    static let amberMid  = UIColor(red: 0x4A/255, green: 0x2E/255, blue: 0x12/255, alpha: 1.0)

    // Boost wrapper (deep plum)
    static let plumDeep    = UIColor(red: 0x2A/255, green: 0x15/255, blue: 0x25/255, alpha: 1.0)
    static let plumMid     = UIColor(red: 0x38/255, green: 0x1C/255, blue: 0x32/255, alpha: 1.0)
    static let purpleLight = UIColor(red: 0.60, green: 0.40, blue: 0.85, alpha: 1.0)
}

// ============================================================
// MARK: - Semantic Color Tokens
// ============================================================

enum AppColor {

    // MARK: Text

    enum Text {
        static let primary   = adaptive(light: Palette.black85, dark: Palette.white)
        static let secondary = adaptive(light: Palette.black45, dark: Palette.white.withAlphaComponent(0.55))
        static let accent    = adaptive(light: Palette.greenText, dark: Palette.greenTextLight)
        static let inverse   = Color(Palette.white)
        static let tertiary  = Color(Palette.black45)
    }

    // MARK: Background

    enum Background {
        static let primary      = adaptive(light: Palette.black10, dark: Palette.black85)
        static let secondary    = adaptive(light: Palette.white, dark: Palette.black85)
        static let card         = adaptive(light: Palette.black10, dark: Palette.black85)
        static let cardElevated = adaptive(light: Palette.white, dark: Palette.black85)
    }

    // MARK: Actions

    enum Action {
        static let complete        = adaptive(light: Palette.green, dark: Palette.greenLight)
        static let priority        = adaptive(light: Palette.yellow, dark: Palette.yellowLight)
        static let archive         = adaptive(light: Palette.blue, dark: Palette.blueHigh)
        static let destructive     = adaptive(light: Palette.black10, dark: Palette.white.withAlphaComponent(0.20))
        static let destructiveIcon = adaptive(light: Palette.black, dark: Palette.white)
        static let red             = adaptive(light: Palette.red, dark: Palette.redLight)
        static let blue            = adaptive(light: Palette.blue, dark: Palette.blueHigh)
    }

    // MARK: Gradients (adaptive light/dark)

    enum Gradient {
        static let cardDefault: [Color] = [
            adaptive(light: Palette.blueLight, dark: Palette.navyDeep),
            adaptive(light: Palette.bluePale, dark: Palette.navyMid),
            adaptive(light: Palette.blueLight, dark: Palette.navyDeep),
            adaptive(light: Palette.blueMid, dark: Palette.navyBright)
        ]
        static let cardOnboarding: [Color] = [
            adaptive(light: Palette.lavenderLight, dark: Palette.violetDeep),
            adaptive(light: Palette.lavenderMid, dark: Palette.violetMid)
        ]
        static let cardBoost: [Color] = [
            adaptive(light: Palette.peachLight, dark: Palette.amberDeep),
            adaptive(light: Palette.peachMid, dark: Palette.amberMid)
        ]
        static let boostWrapper: [Color] = [
            adaptive(light: Palette.pinkLight, dark: Palette.plumDeep),
            adaptive(light: Palette.pinkMid, dark: Palette.plumMid)
        ]
        static let boostAccent = adaptive(light: Palette.purple, dark: Palette.purpleLight)
    }

    // MARK: Icon gradients
    
    enum Icon {
        /// Gradient for liquid glass icon foregrounds (top-left to bottom-right)
        static let foregroundGradient = LinearGradient(
            colors: [
                Color(Palette.black85),
                Color(Palette.black85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Gradient for liquid glass button strokes
        static let strokeGradient = LinearGradient(
            colors: [
                Color(Palette.black45),
                Color(Palette.black10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Surface helpers

    static let overlay      = adaptive(light: Palette.black10, dark: Palette.white.withAlphaComponent(0.15))
    static let scrim        = Color(Palette.black45)
    static let shadow       = Color(Palette.black10)
    static let shadowMedium = Color(Palette.black10)
    
    /// System backgrounds (adaptive)
    static let systemBackground         = Color(uiColor: .systemBackground)
    static let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
    static let tertiarySystemBackground  = Color(uiColor: .tertiarySystemBackground)
    
    /// UI element colors
    static let dragHandle     = Color(Palette.black45)
    static let debugText      = Color(Palette.black60)
    static let emptyStateIcon = Color(Palette.black60)

    static let slotFill   = Color(Palette.white.withAlphaComponent(0.05))
    static let slotStroke = Color(Palette.white.withAlphaComponent(0.15))
    static let slotCircle = Color(Palette.white.withAlphaComponent(0.10))
    static let slotIcon   = Color(Palette.white.withAlphaComponent(0.35))
    static let slotLabel  = Color(Palette.white.withAlphaComponent(0.35))

    // MARK: - Helper

    fileprivate static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

// ============================================================
// MARK: - Text Style Tokens
// ============================================================

enum AppFont {
    static let title1   = Font.system(size: 38, weight: .bold, design: .rounded)
    static let title2   = Font.system(size: 22, weight: .semibold)
    static let title3   = Font.system(size: 20, weight: .bold)
    static let body1    = Font.system(size: 18, weight: .medium)
    static let body2    = Font.system(size: 16, weight: .medium)
    static let caption  = Font.system(size: 13, weight: .medium)
    static let footnote = Font.system(size: 12, weight: .regular)
}
