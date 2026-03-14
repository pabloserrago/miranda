import SwiftUI

// ============================================================
// MARK: - Palette (raw color values, defined once)
// ============================================================

enum Palette {

    // Neutrals
    static let white   = UIColor(white: 1.0, alpha: 1.0)
    static let black   = UIColor(white: 0.0, alpha: 1.0)
    static let black85 = UIColor(white: 0.0, alpha: 0.85)
    static let black40 = UIColor(white: 0.0, alpha: 0.40)
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
    static let red  = UIColor.systemRed
    static let blue = UIColor.systemBlue

    // Gradient: Card Default
    static let blueLight = UIColor(red: 0xCC/255, green: 0xDA/255, blue: 0xF7/255, alpha: 1.0)
    static let bluePale  = UIColor(red: 0xE7/255, green: 0xED/255, blue: 0xF9/255, alpha: 1.0)
    static let blueMid   = UIColor(red: 0x60/255, green: 0x90/255, blue: 0xEA/255, alpha: 1.0)

    // Gradient: Onboarding
    static let lavenderLight = UIColor(red: 0.92, green: 0.92, blue: 0.98, alpha: 1.0)
    static let lavenderDark  = UIColor(red: 0.88, green: 0.88, blue: 0.96, alpha: 1.0)

    // Gradient: Boost
    static let peachLight = UIColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0)
    static let peachDark  = UIColor(red: 0.98, green: 0.80, blue: 0.60, alpha: 1.0)

    // Gradient: Boost wrapper
    static let pinkLight = UIColor(red: 0.95, green: 0.80, blue: 0.92, alpha: 1.0)
    static let pinkDark  = UIColor(red: 0.90, green: 0.75, blue: 0.90, alpha: 1.0)
    static let purple    = UIColor(red: 0.45, green: 0.25, blue: 0.70, alpha: 1.0)
}

// ============================================================
// MARK: - Semantic Color Tokens
// ============================================================

enum AppColor {

    // MARK: Text

    enum Text {
        static let primary   = adaptive(light: Palette.black85, dark: Palette.white)
        static let secondary = adaptive(light: Palette.black40, dark: Palette.white.withAlphaComponent(0.55))
        static let accent    = adaptive(light: Palette.greenText, dark: Palette.greenTextLight)
        static let inverse   = Color(Palette.white)
        static let tertiary  = Color(Palette.black40)
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
        static let destructive     = adaptive(light: Palette.black10, dark: Palette.white.withAlphaComponent(0.20))
        static let destructiveIcon = adaptive(light: Palette.black, dark: Palette.white)
    }

    // MARK: Gradients

    enum Gradient {
        static let cardDefault: [Color] = [
            Color(Palette.blueLight), Color(Palette.bluePale),
            Color(Palette.blueLight), Color(Palette.blueMid)
        ]
        static let cardOnboarding: [Color] = [
            Color(Palette.lavenderLight), Color(Palette.lavenderDark)
        ]
        static let cardBoost: [Color] = [
            Color(Palette.peachLight), Color(Palette.peachDark)
        ]
        static let boostWrapper: [Color] = [
            Color(Palette.pinkLight), Color(Palette.pinkDark)
        ]
        static let boostAccent = Color(Palette.purple)
    }

    // MARK: Surface helpers

    static let overlay      = adaptive(light: Palette.black10, dark: Palette.white.withAlphaComponent(0.15))
    static let scrim        = Color(Palette.black40)
    static let shadow       = Color(Palette.black10)
    static let shadowMedium = Color(Palette.black10)

    static let slotFill   = Color(Palette.white.withAlphaComponent(0.05))
    static let slotStroke = Color(Palette.white.withAlphaComponent(0.15))
    static let slotCircle = Color(Palette.white.withAlphaComponent(0.10))
    static let slotIcon   = Color(Palette.white.withAlphaComponent(0.35))
    static let slotLabel  = Color(Palette.white.withAlphaComponent(0.35))

    // MARK: - Helper

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
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
