import SwiftUI

// ============================================================
// MARK: - Raw Palette Ramps
// ============================================================

enum Palette {
    
    // MARK: Neutral Ramp (white to black)
    // 50 = lightest, 900 = darkest
    static let neutral50  = UIColor(white: 1.0, alpha: 1.0)      // Pure white
    static let neutral100 = UIColor(white: 0.98, alpha: 1.0)   // Off-white
    static let neutral200 = UIColor(white: 0.95, alpha: 1.0)   // Very light gray
    static let neutral300 = UIColor(white: 0.90, alpha: 1.0)   // Light gray
    static let neutral400 = UIColor(white: 0.75, alpha: 1.0)   // Medium-light gray
    static let neutral500 = UIColor(white: 0.50, alpha: 1.0)   // Mid gray
    static let neutral600 = UIColor(white: 0.35, alpha: 1.0)  // Medium-dark gray
    static let neutral700 = UIColor(white: 0.20, alpha: 1.0)  // Dark gray
    static let neutral800 = UIColor(white: 0.10, alpha: 1.0)  // Very dark gray
    static let neutral900 = UIColor(white: 0.0, alpha: 1.0)   // Pure black
    
    // MARK: Green Ramp (light to dark)
    static let green50  = UIColor(red: 0.30, green: 0.85, blue: 0.40, alpha: 1.0)  // Lightest
    static let green100 = UIColor(red: 0.25, green: 0.80, blue: 0.35, alpha: 1.0)
    static let green200 = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0)  // Base
    static let green300 = UIColor(red: 0.20, green: 0.70, blue: 0.30, alpha: 1.0)
    static let green400 = UIColor(red: 0.20, green: 0.65, blue: 0.25, alpha: 1.0)  // Text accent
    static let green500 = UIColor(red: 0.15, green: 0.55, blue: 0.20, alpha: 1.0)
    static let green600 = UIColor(red: 0.10, green: 0.45, blue: 0.15, alpha: 1.0)
    static let green700 = UIColor(red: 0.05, green: 0.35, blue: 0.10, alpha: 1.0)  // Darkest
    
    // MARK: Blue Ramp (light to dark)
    static let blue50  = UIColor(red: 0xCC/255, green: 0xDA/255, blue: 0xF7/255, alpha: 1.0)  // Lightest (pastel)
    static let blue100 = UIColor(red: 0xE7/255, green: 0xED/255, blue: 0xF9/255, alpha: 1.0)  // Pale
    static let blue200 = UIColor(red: 0.0, green: 0.60, blue: 1.0, alpha: 1.0)  // Bright
    static let blue300 = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)  // Base
    static let blue400 = UIColor(red: 0x60/255, green: 0x90/255, blue: 0xEA/255, alpha: 1.0)  // Mid
    static let blue500 = UIColor(red: 0.25, green: 0.61, blue: 1.0, alpha: 1.0)  // High
    static let blue600 = UIColor(red: 0x2D/255, green: 0x45/255, blue: 0x70/255, alpha: 1.0)  // Bright dark
    static let blue700 = UIColor(red: 0x1F/255, green: 0x2D/255, blue: 0x4A/255, alpha: 1.0)  // Mid dark
    static let blue800 = UIColor(red: 0x1A/255, green: 0x25/255, blue: 0x40/255, alpha: 1.0)  // Deep dark
    
    // MARK: Red Ramp (light to dark)
    static let red50  = UIColor(red: 1.0, green: 0.40, blue: 0.40, alpha: 1.0)  // Lightest
    static let red100 = UIColor(red: 1.0, green: 0.35, blue: 0.37, alpha: 1.0)  // Light
    static let red200 = UIColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1.0)
    static let red300 = UIColor(red: 0.90, green: 0.22, blue: 0.21, alpha: 1.0)  // Base
    static let red400 = UIColor(red: 0.80, green: 0.18, blue: 0.18, alpha: 1.0)
    static let red500 = UIColor(red: 0.70, green: 0.15, blue: 0.15, alpha: 1.0)
    static let red600 = UIColor(red: 0.60, green: 0.12, blue: 0.12, alpha: 1.0)
    static let red700 = UIColor(red: 0.50, green: 0.10, blue: 0.10, alpha: 1.0)  // Darkest
    
    // MARK: Yellow/Amber Ramp (light to dark)
    static let yellow50  = UIColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 1.0)  // Lightest (peach)
    static let yellow100 = UIColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0)  // Light (peach)
    static let yellow200 = UIColor(red: 1.0, green: 0.88, blue: 0.60, alpha: 1.0)  // Mid (peach)
    static let yellow300 = UIColor(red: 1.0, green: 0.84, blue: 0.04, alpha: 1.0)  // Light yellow
    static let yellow400 = UIColor(red: 1.0, green: 0.80, blue: 0.0, alpha: 1.0)  // Base yellow
    static let yellow500 = UIColor(red: 0.98, green: 0.75, blue: 0.0, alpha: 1.0)
    static let yellow600 = UIColor(red: 0x4A/255, green: 0x2E/255, blue: 0x12/255, alpha: 1.0)  // Amber mid dark
    static let yellow700 = UIColor(red: 0x35/255, green: 0x22/255, blue: 0x0E/255, alpha: 1.0)  // Amber deep dark
    
    // MARK: Purple Ramp (light to dark)
    static let purple50  = UIColor(red: 0.95, green: 0.92, blue: 0.98, alpha: 1.0)  // Lightest (lavender)
    static let purple100 = UIColor(red: 0.92, green: 0.92, blue: 0.98, alpha: 1.0)  // Light (lavender)
    static let purple200 = UIColor(red: 0.88, green: 0.88, blue: 0.96, alpha: 1.0)  // Mid (lavender)
    static let purple300 = UIColor(red: 0.95, green: 0.80, blue: 0.92, alpha: 1.0)  // Light (pink)
    static let purple400 = UIColor(red: 0.90, green: 0.75, blue: 0.90, alpha: 1.0)  // Mid (pink)
    static let purple500 = UIColor(red: 0.60, green: 0.40, blue: 0.85, alpha: 1.0)  // Light purple
    static let purple600 = UIColor(red: 0.45, green: 0.25, blue: 0.70, alpha: 1.0)  // Base purple
    static let purple700 = UIColor(red: 0x38/255, green: 0x1C/255, blue: 0x32/255, alpha: 1.0)  // Mid dark (plum)
    static let purple800 = UIColor(red: 0x2D/255, green: 0x26/255, blue: 0x42/255, alpha: 1.0)  // Violet mid dark
    static let purple900 = UIColor(red: 0x2A/255, green: 0x15/255, blue: 0x25/255, alpha: 1.0)  // Deep dark (plum)
    static let purple950 = UIColor(red: 0x20/255, green: 0x1C/255, blue: 0x30/255, alpha: 1.0)  // Deepest (violet)
}

// ============================================================
// MARK: - Semantic Color Tokens (derived from ramps)
// ============================================================

enum AppColor {
    
    // MARK: Text
    
    enum Text {
        // Primary text: high contrast, adaptive
        static let primary = adaptive(light: Palette.neutral900, dark: Palette.neutral50)
        
        // Secondary text: medium contrast, adaptive
        static let secondary = adaptive(light: Palette.neutral500, dark: Palette.neutral400)
        
        // Tertiary text: low contrast
        static let tertiary = adaptive(light: Palette.neutral400, dark: Palette.neutral500)
        
        // Inverse text: for use on colored backgrounds
        static let inverse = Color(Palette.neutral50)
    }
    
    // MARK: Surface
    
    enum Surface {
        // Primary surface: main background
        static let primary = adaptive(light: Palette.neutral50, dark: Palette.neutral900)
        
        // Secondary surface: elevated/card background
        static let secondary = adaptive(light: Palette.neutral50, dark: Palette.neutral800)
        
        // Tertiary surface: subtle background
        static let tertiary = adaptive(light: Palette.neutral100, dark: Palette.neutral800)
        
        // Elevated surface: cards, modals
        static let elevated = adaptive(light: Palette.neutral50, dark: Palette.neutral800)
        
        // Card background: subtle tint
        static let card = adaptive(light: Palette.neutral100, dark: Palette.neutral800)
        
        // UIKit compatibility (UIColor versions)
        static let primaryUIColor: UIColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? Palette.neutral900 : Palette.neutral50
        }
        static let secondaryUIColor: UIColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? Palette.neutral800 : Palette.neutral50
        }
        static let tertiaryUIColor: UIColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? Palette.neutral800 : Palette.neutral100
        }
        static let buttonUIColor: UIColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? Palette.neutral200 : Palette.neutral800
        }
    }
    
    // MARK: Border
    
    enum Border {
        // Subtle border: dividers, separators
        static let subtle = adaptive(light: Palette.neutral200, dark: Palette.neutral700)
        
        // Strong border: emphasis, focus
        static let strong = adaptive(light: Palette.neutral400, dark: Palette.neutral600)
    }
    
    // MARK: Status/Action Colors
    
    enum Status {
        // Accent: primary brand color (green)
        static let accent = adaptive(light: Palette.green200, dark: Palette.green100)
        
        // Success: positive actions (green)
        static let success = adaptive(light: Palette.green200, dark: Palette.green100)
        
        // Warning: caution (yellow)
        static let warning = adaptive(light: Palette.yellow400, dark: Palette.yellow300)
        
        // Error: destructive (red)
        static let error = adaptive(light: Palette.red300, dark: Palette.red100)
        
        // Info: informational (blue)
        static let info = adaptive(light: Palette.blue300, dark: Palette.blue500)
    }
    
    // MARK: Actions (legacy compatibility, map to Status)
    
    enum Action {
        static let complete = Status.success
        static let priority = Status.warning
        static let archive = Status.info
        static let red = Status.error
        static let blue = Status.info
        static let destructive = adaptive(light: Palette.neutral800, dark: Palette.neutral200)
        static let destructiveIcon = adaptive(light: Palette.neutral900, dark: Palette.neutral50)
    }
    
    // MARK: Gradients (derived from ramps)
    
    enum Gradient {
        // Card Default: blue gradient
        static let cardDefault: [Color] = [
            adaptive(light: Palette.blue50, dark: Palette.blue800),
            adaptive(light: Palette.blue100, dark: Palette.blue700),
            adaptive(light: Palette.blue50, dark: Palette.blue800),
            adaptive(light: Palette.blue400, dark: Palette.blue600)
        ]
        
        // Card Onboarding: purple/lavender gradient
        static let cardOnboarding: [Color] = [
            adaptive(light: Palette.purple100, dark: Palette.purple950),
            adaptive(light: Palette.purple200, dark: Palette.purple800)
        ]
        
        // Card Boost: yellow/peach gradient
        static let cardBoost: [Color] = [
            adaptive(light: Palette.yellow100, dark: Palette.yellow700),
            adaptive(light: Palette.yellow200, dark: Palette.yellow600)
        ]
        
        // Boost wrapper: pink gradient
        static let boostWrapper: [Color] = [
            adaptive(light: Palette.purple300, dark: Palette.purple900),
            adaptive(light: Palette.purple400, dark: Palette.purple700)
        ]
        
        // Boost accent: purple
        static let boostAccent = adaptive(light: Palette.purple600, dark: Palette.purple500)
    }
    
    // MARK: Icon gradients
    
    enum Icon {
        /// Gradient for liquid glass icon foregrounds
        static let foregroundGradient = LinearGradient(
            colors: [
                Color(Palette.neutral900),
                Color(Palette.neutral900)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Gradient for liquid glass button strokes
        static let strokeGradient = LinearGradient(
            colors: [
                Color(Palette.neutral500),
                Color(Palette.neutral800)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: Surface helpers
    
    static let overlay = adaptive(light: Palette.neutral800, dark: Palette.neutral200)
    static let scrim = Color(Palette.neutral500)
    static let shadow = Color(Palette.neutral800)
    static let shadowMedium = Color(Palette.neutral800)
    
    /// System backgrounds (derived from ramps)
    static let systemBackground = Surface.primary
    static let secondarySystemBackground = Surface.secondary
    static let tertiarySystemBackground = Surface.tertiary
    
    /// UI element colors
    static let dragHandle = Color(Palette.neutral500)
    static let debugText = Color(Palette.neutral600)
    static let emptyStateIcon = Color(Palette.neutral600)
    
    static let slotFill = Color(Palette.neutral50.withAlphaComponent(0.05))
    static let slotStroke = Color(Palette.neutral50.withAlphaComponent(0.15))
    static let slotCircle = Color(Palette.neutral50.withAlphaComponent(0.10))
    static let slotIcon = Color(Palette.neutral50.withAlphaComponent(0.35))
    static let slotLabel = Color(Palette.neutral50.withAlphaComponent(0.35))
    
    // MARK: - Helper
    
    fileprivate static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

// ============================================================
// MARK: - Text Style Tokens
// ============================================================

enum AppFont {
    static let title1 = Font.system(size: 38, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold)
    static let title3 = Font.system(size: 20, weight: .bold)
    static let body1 = Font.system(size: 18, weight: .medium)
    static let body2 = Font.system(size: 16, weight: .medium)
    static let caption = Font.system(size: 13, weight: .medium)
    static let footnote = Font.system(size: 12, weight: .regular)
}
