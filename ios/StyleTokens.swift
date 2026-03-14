import SwiftUI

// ============================================================
// MARK: - Palette (raw color values, defined once)
// ============================================================

enum Palette {

    // Neutrals
    static let white       = UIColor(white: 1.0, alpha: 1.0)
    static let black       = UIColor(white: 0.0, alpha: 1.0)
    static let black85     = UIColor(white: 0.0, alpha: 0.85)
    static let black45     = UIColor(white: 0.0, alpha: 0.45)
    static let black08     = UIColor(white: 0.0, alpha: 0.08)
    static let black09     = UIColor(white: 0.0, alpha: 0.09)
    static let white55     = UIColor(white: 1.0, alpha: 0.55)
    static let white20     = UIColor(white: 1.0, alpha: 0.20)
    static let white15     = UIColor(white: 1.0, alpha: 0.15)

    // Grays
    static let gray900     = UIColor(red: 0x1C/255, green: 0x1C/255, blue: 0x1E/255, alpha: 1.0)  // #1C1C1E
    static let gray800     = UIColor(red: 0x2C/255, green: 0x2C/255, blue: 0x2E/255, alpha: 1.0)  // #2C2C2E
    static let gray700     = UIColor(red: 0x3A/255, green: 0x3A/255, blue: 0x3C/255, alpha: 1.0)  // #3A3A3C
    static let gray100     = UIColor(red: 0xF2/255, green: 0xF2/255, blue: 0xF7/255, alpha: 1.0)  // #F2F2F7

    // Green
    static let green500    = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0)
    static let green400    = UIColor(red: 0.30, green: 0.85, blue: 0.40, alpha: 1.0)

    // Yellow
    static let yellow500   = UIColor(red: 1.0, green: 0.80, blue: 0.0, alpha: 1.0)
    static let yellow400   = UIColor(red: 1.0, green: 0.84, blue: 0.04, alpha: 1.0)

    // Accent green (text)
    static let accent500   = UIColor(red: 0.20, green: 0.65, blue: 0.25, alpha: 1.0)
    static let accent400   = UIColor(red: 0.40, green: 0.85, blue: 0.45, alpha: 1.0)
}

// ============================================================
// MARK: - Semantic Color Tokens
// ============================================================

enum AppColor {

    // MARK: Text

    enum Text {
        /// Primary text: black85 (light) / white (dark)
        static let primary = adaptive(light: Palette.black85, dark: Palette.white)

        /// Secondary text: black45 (light) / white55 (dark)
        static let secondary = adaptive(light: Palette.black45, dark: Palette.white55)

        /// Accent text: accent500 (light) / accent400 (dark)
        static let accent = adaptive(light: Palette.accent500, dark: Palette.accent400)
    }

    // MARK: Background

    enum Background {
        /// Main screen: gray100 (light) / gray900 (dark)
        static let primary = adaptive(light: Palette.gray100, dark: Palette.gray900)

        /// Drawer, secondary surfaces: white (light) / gray800 (dark)
        static let secondary = adaptive(light: Palette.white, dark: Palette.gray800)

        /// Card surface: gray100 (light) / gray800 (dark)
        static let card = adaptive(light: Palette.gray100, dark: Palette.gray800)

        /// Elevated card: white (light) / gray700 (dark)
        static let cardElevated = adaptive(light: Palette.white, dark: Palette.gray700)
    }

    // MARK: Actions

    enum Action {
        /// Complete button: green500 (light) / green400 (dark)
        static let complete = adaptive(light: Palette.green500, dark: Palette.green400)

        /// Priority button: yellow500 (light) / yellow400 (dark)
        static let priority = adaptive(light: Palette.yellow500, dark: Palette.yellow400)

        /// Destructive / dismiss fill: black08 (light) / white20 (dark)
        static let destructive = adaptive(light: Palette.black08, dark: Palette.white20)
    }

    // MARK: Surface helpers

    /// Overlay tint: black08 (light) / white15 (dark)
    static let overlay = adaptive(light: Palette.black08, dark: Palette.white15)

    /// Drop shadow
    static let shadow = Color(Palette.black09)

    // MARK: - Helper

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

// ============================================================
// MARK: - Text Style Tokens
// ============================================================

enum AppFont {
    /// 38pt bold rounded - full-screen card title
    static let title1 = Font.system(size: 38, weight: .bold, design: .rounded)

    /// 22pt semibold - section headers
    static let title2 = Font.system(size: 22, weight: .semibold)

    /// 20pt bold - primary buttons, nav actions
    static let title3 = Font.system(size: 20, weight: .bold)

    /// 18pt medium - card body text, picker items
    static let body1 = Font.system(size: 18, weight: .medium)

    /// 16pt medium - list row text, search field
    static let body2 = Font.system(size: 16, weight: .medium)

    /// 13pt medium - labels, small UI elements
    static let caption = Font.system(size: 13, weight: .medium)

    /// 12pt regular - fine print, timestamps
    static let footnote = Font.system(size: 12, weight: .regular)
}
