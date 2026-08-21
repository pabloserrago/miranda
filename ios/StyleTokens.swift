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

    // MARK: Translucent ink
    // Text de-emphasis is expressed as opacity over the surface rather than as
    // a fixed grey, so a label keeps the same relationship to its background
    // whichever surface it lands on.

    /// Black at `opacity` — light-mode text de-emphasis.
    static func ink(_ opacity: CGFloat) -> UIColor {
        UIColor.black.withAlphaComponent(opacity)
    }

    /// White at `opacity` — dark-mode text de-emphasis.
    static func paper(_ opacity: CGFloat) -> UIColor {
        UIColor.white.withAlphaComponent(opacity)
    }

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

    // MARK: Teal — cool blue-green (Card theme: Nostalgia)
    static let teal25  = UIColor(hex: 0xEAF5F2) // #EAF5F2  ← step 99
    static let teal200 = UIColor(hex: 0xA8E0D6) // #A8E0D6  ← step 90
    static let teal800 = UIColor(hex: 0x0E4038) // #0E4038  ← step 20
    static let teal950 = UIColor(hex: 0x0A201D) // #0A201D  ← step 5

    // MARK: Citron — acid comic yellow (Card theme: Nostalgia accent)
    // Deliberately not part of the Yellow ramp: `DayPhase` uses yellow200/600 as
    // its sunrise tint, and a stop that equals its own tint stops responding to
    // the time of day.
    static let citron300 = UIColor(hex: 0xF3E34C) // #F3E34C  ← step 80
    static let citron800 = UIColor(hex: 0x3E3A10) // #3E3A10  ← step 20

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
// MARK: - Background Theme
// ============================================================

/// A light/dark color pair before it becomes a dynamic `Color`.
struct ColorStop {
    let light: UIColor
    let dark: UIColor
}

/// The widget background follows the clock in three eight-hour stretches: a
/// warm sunrise, a neutral working day and a cool sunset. Phases are anchored
/// to fixed hours rather than to real solar times, so no location is needed and
/// the result is deterministic.
///
/// The app's own background does not follow this — it keeps rendering the
/// untinted theme through the cloud shader.
enum DayPhase {
    /// 06:00–14:00, warm.
    case sunrise
    /// 14:00–22:00, untinted; the reference the other two shift away from.
    case working
    /// 22:00–06:00, cool.
    case sunset

    static func phase(at date: Date, calendar: Calendar = .current) -> DayPhase {
        switch calendar.component(.hour, from: date) {
        case 6..<14:  return .sunrise
        case 14..<22: return .working
        default:      return .sunset
        }
    }

    // MARK: Tint

    /// How far a stop moves toward its phase tint at full strength. Tuned
    /// against `ContrastTests`, which is what caps it: warmer stops lighten,
    /// and `Text.secondary` has the least headroom.
    private static let strength: CGFloat = 0.22

    private struct Anchor {
        /// Hour of the day where this tint is at full strength — the midpoint
        /// of its phase, so each phase fully reaches its own character.
        let hour: Double
        let tint: ColorStop
        let strength: CGFloat
    }

    /// Full-strength moments, in order across a day that starts at the sunset
    /// anchor. The first entry repeats at the end so the wrap past midnight
    /// interpolates instead of jumping. The working anchor sits at strength 0,
    /// which makes its color inert — it is the untinted reference.
    private static let anchors: [Anchor] = [
        Anchor(hour: 2,  tint: ColorStop(light: Palette.blue200,   dark: Palette.blue800),   strength: strength),
        Anchor(hour: 10, tint: ColorStop(light: Palette.yellow200, dark: Palette.yellow600), strength: strength),
        Anchor(hour: 18, tint: ColorStop(light: Palette.neutral100, dark: Palette.neutral800), strength: 0),
        Anchor(hour: 26, tint: ColorStop(light: Palette.blue200,   dark: Palette.blue800),   strength: strength),
    ]

    /// Blends `base` toward `tint` by `amount`, where 0 leaves the base
    /// untouched and 1 returns the tint.
    static func blend(_ base: UIColor, toward tint: UIColor, amount: CGFloat) -> UIColor {
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        base.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        tint.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        let t = min(max(amount, 0), 1)
        return UIColor(red:   br + (tr - br) * t,
                       green: bg + (tg - bg) * t,
                       blue:  bb + (tb - bb) * t,
                       alpha: ba)
    }

    /// Shifts a theme stop toward the temperature of the moment. Between two
    /// anchors the two tints are applied in sequence, so the result lands on
    /// one anchor exactly at its hour and eases across the hours between.
    static func tinted(_ stop: ColorStop, at date: Date, calendar: Calendar = .current) -> ColorStop {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let rawHour = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60
        // Anchors run 2...26, so pull the small hours up into that window.
        let hour = rawHour < anchors[0].hour ? rawHour + 24 : rawHour

        guard let index = (0..<(anchors.count - 1)).first(where: {
            hour >= anchors[$0].hour && hour < anchors[$0 + 1].hour
        }) else {
            return stop
        }

        let from = anchors[index]
        let to = anchors[index + 1]
        let progress = CGFloat((hour - from.hour) / (to.hour - from.hour))

        func shift(_ base: UIColor, _ pick: (ColorStop) -> UIColor) -> UIColor {
            let fading = blend(base, toward: pick(from.tint), amount: from.strength * (1 - progress))
            return blend(fading, toward: pick(to.tint), amount: to.strength * progress)
        }

        return ColorStop(light: shift(stop.light, \.light),
                         dark:  shift(stop.dark,  \.dark))
    }

    // MARK: Timeline schedule

    private static let entryInterval: TimeInterval = 30 * 60
    private static let scheduleSpan: TimeInterval = 24 * 60 * 60

    /// Moments the widget should re-render so the background keeps pace with
    /// the clock. Pre-rendered entries cost nothing against the widget refresh
    /// budget, unlike asking WidgetKit to reload us every half hour.
    static func entryDates(from start: Date) -> [Date] {
        stride(from: 0, to: scheduleSpan, by: entryInterval)
            .map { start.addingTimeInterval($0) }
    }
}

/// User-selectable app background. `standard` keeps the flat neutral
/// backdrop; the colorful presets render a procedural cloud layer
/// (FBM noise shader) behind the Liquid Glass cards. All stops stay in
/// the 25–200 light / 700–950 dark range to keep colors muted.
enum BackgroundTheme: String, CaseIterable {

    /// Flat neutral backdrop — the original default, no cloud layer.
    case standard
    /// Rose + lavender clouds.
    case bloom
    /// Sage + lavender clouds.
    case meadow
    /// Periwinkle + rose clouds.
    case dusk
    /// Teal + warm ochre clouds — retro comic palette.
    case nostalgia

    /// Themes offered in the Settings and onboarding pickers.
    ///
    /// The picker is a fixed row of swatches beside its label, which fits four
    /// before the label starts wrapping. Nostalgia is fully implemented and
    /// still reachable from the Cloud Lab, but stays out of this list until the
    /// row gets a layout that scales past four.
    static let selectable: [BackgroundTheme] = [.standard, .bloom, .meadow, .dusk]

    var label: String {
        switch self {
        case .standard:  return String(localized: "background.standard",  defaultValue: "Standard")
        case .bloom:     return String(localized: "background.bloom",     defaultValue: "Bloom")
        case .meadow:    return String(localized: "background.meadow",    defaultValue: "Meadow")
        case .dusk:      return String(localized: "background.dusk",      defaultValue: "Dusk")
        case .nostalgia: return String(localized: "background.nostalgia", defaultValue: "Nostalgia")
        }
    }

    /// The raw light/dark pairs behind `cloudColors`. Kept separate from the
    /// dynamic colors so the time-of-day tint can blend concrete values, which
    /// a dynamic `Color` does not allow without resolving traits by hand.
    ///
    /// Stop order matters: FBM noise concentrates around mid values, so the
    /// first two stops carry the preset's dominant hue and the third is the
    /// accent that appears in the cloud peaks.
    var cloudStops: [ColorStop] {
        switch self {
        case .standard:
            return []
        case .bloom:
            return [ColorStop(light: Palette.rose25,      dark: Palette.rose950),
                    ColorStop(light: Palette.rose100,     dark: Palette.rose900),
                    ColorStop(light: Palette.lavender200, dark: Palette.lavender700)]
        case .meadow:
            return [ColorStop(light: Palette.sage25,      dark: Palette.sage950),
                    ColorStop(light: Palette.sage100,     dark: Palette.sage900),
                    ColorStop(light: Palette.lavender200, dark: Palette.lavender700)]
        case .dusk:
            return [ColorStop(light: Palette.blue25,      dark: Palette.blue950),
                    ColorStop(light: Palette.blue100,     dark: Palette.blue900),
                    ColorStop(light: Palette.rose200,     dark: Palette.rose700)]
        case .nostalgia:
            return [ColorStop(light: Palette.teal25,      dark: Palette.teal950),
                    ColorStop(light: Palette.teal200,     dark: Palette.teal800),
                    ColorStop(light: Palette.citron300,   dark: Palette.citron800)]
        }
    }

    /// Three cloud color stops (low → mid → high noise value), adaptive
    /// light/dark. Empty for `standard`, which draws no cloud layer.
    var cloudColors: [Color] {
        cloudStops.map { adaptive(light: $0.light, dark: $0.dark) }
    }

    /// The same stops shifted toward the time-of-day temperature.
    func cloudColors(at date: Date) -> [Color] {
        cloudStops
            .map { DayPhase.tinted($0, at: date) }
            .map { adaptive(light: $0.light, dark: $0.dark) }
    }

    /// Noise-domain offset — tuned in the Cloud Lab; all presets share the
    /// same arrangement so switching themes only changes the palette.
    var cloudSeed: Float {
        self == .standard ? 0 : 3
    }

    /// 3x3 arrangement of `cloudColors` for the widget mesh gradient, as indices
    /// into the stops. The dominant hue (0, 1) covers the grid and the accent (2)
    /// stays in two cells, mirroring how the shader only surfaces it in the
    /// cloud peaks.
    static let widgetMeshLayout = [0, 1, 0,
                                   1, 0, 2,
                                   0, 2, 1]

    /// Nine mesh stops for the widget background at a given moment. WidgetKit
    /// renders from an archived view out of process, so the app's Metal cloud
    /// shader can't run there — a mesh gradient over the same three stops keeps
    /// the palette while approximating the shape. Empty for `standard`, which
    /// stays neutral at every hour.
    func widgetMeshColors(at date: Date) -> [Color] {
        let stops = cloudColors(at: date)
        guard stops.count == 3 else { return [] }
        return Self.widgetMeshLayout.map { stops[$0] }
    }

    /// Three representative colors for the Settings swatch.
    var swatchColors: [Color] {
        switch self {
        case .standard:
            return [Material.Surface.backdrop,
                    adaptive(light: Palette.neutral100, dark: Palette.neutral800),
                    adaptive(light: Palette.neutral200, dark: Palette.neutral700)]
        case .bloom, .meadow, .dusk, .nostalgia:
            return cloudColors
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
        static let secondary = adaptive(light: Palette.neutral100,  dark: Palette.neutral800)    // elevated panels: drawer, sheets, toast, analytics cards, mic chip fill, recent note rows
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
        // Secondary and tertiary are translucent ink rather than fixed greys, so
        // they hold the same relative step down from primary on every surface
        // they sit on instead of drifting toward the background on darker fills.
        static let secondary = adaptive(light: Palette.ink(0.60), dark: Palette.paper(0.70)) // supporting labels, captions, hints, settings descriptions, debug rows, GhostButtonStyle, widget muted text
        static let tertiary  = adaptive(light: Palette.ink(0.55), dark: Palette.paper(0.55)) // subtle: input placeholders, widget secondary links, SolidButtonStyle disabled label
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
        static let title:   CGFloat = 34   // AppFont.title
        static let priority: CGFloat = 20   // AppFont.priority — priority card body text
        static let headline: CGFloat = 22  // AppFont.headline
        static let icon:    CGFloat = 20   // AppFont.icon
        static let body:    CGFloat = 17   // AppFont.body
        static let subhead: CGFloat = 14   // AppFont.subhead — widget large secondary rows
        static let label:   CGFloat = 13   // AppFont.label
        static let caption: CGFloat = 12   // AppFont.caption, widget medium secondary rows
        static let micro:   CGFloat = 10   // AppFont.micro
        
        static let widgetHero:      CGFloat = 34  // AppFont.widgetHero — medium widget rank-0
        static let widgetLargeHero: CGFloat = 24  // AppFont.widgetLargeHero — large widget rank-0
        
        enum Tracking {
            static let widgetHero:      CGFloat = -1.02   // medium widget rank-0 (-3% of 34)
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
        static let primary     = adaptive(light: Palette.red900,  dark: Palette.red700)     // ActionChip.accent icon, Text.accent, Card.accent, settings tint
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
        static let card: CGFloat = 32
        static let chip: CGFloat = full
        static let drawer: CGFloat = 28
        static let input: CGFloat = 26
        static let container: CGFloat = 26  // grouped settings section container
        static let control: CGFloat = 26
        static let handle: CGFloat = 8
        static let appIcon: CGFloat = 14
        
        // Component sizing (diameter)
        static let chipLarge: CGFloat = 60
        static let chipMedium: CGFloat = 48
        static let chipSmall: CGFloat = 44
    }
    
    // MARK: Elevation — shadow & overlay
    
    enum Elevation {
        static let shadow    = adaptive(light: Palette.neutral400, dark: Palette.neutral950) // CardSurface, CloseButton, toast, toolbar buttons, settings cards, widget capsule
        static let scrim     = adaptive(light: Palette.neutral950, dark: Palette.neutral950) // drawer drag handle track fill
    }
    
    // MARK: Status — semantic colored signals
    
    enum Status {
        static let success = adaptive(light: Palette.green200, dark: Palette.green100) // complete action chip, settings app icon previews (Messages, Phone)
        static let warning = adaptive(light: Palette.yellow400, dark: Palette.yellow300) // priority action chip, Card.boost gradient
        static let error   = adaptive(light: Palette.red500,   dark: Palette.red100)   // destructive actions (Delete All), settings app icon preview (Photos)
        static let info    = adaptive(light: Palette.blue300,   dark: Palette.blue500)  // archive action chip, settings gradient, Card.wrapper gradient, debug emphasis
    }
    
    // MARK: Card — gradient arrays
    
    enum Card {
        static let gradients: [[Color]] = [
            [Control.fillTertiary, Control.fillPrimary],                        // white-blue → cornflower
            [Control.fillSecondary, Control.fillPrimary],                       // lavender → cornflower
            [Control.fillTertiary, Control.fillSecondary, Control.fillPrimary], // smoother three-stop sweep
        ]

        // MARK: Priority card fill — single flat neutral surface for all positions
        private static let priorityFill: [Color] = [adaptive(light: Palette.neutral0, dark: Palette.neutral950)]

        static func colors(for index: Int) -> [Color] {
            priorityFill
        }

        // MARK: Priority card border
        static let border: Color      = adaptive(light: Palette.neutral0, dark: Palette.neutral700)
        static let borderWidth: CGFloat = 3

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

    /// Each in-app token, paired with the Dynamic Type style it scales against.
    ///
    /// Scaling from the documented `Material.Typography` size — rather than
    /// adopting a bare `Font.system(.body)` — keeps the design scale intact at
    /// the default content size while still honouring Larger Text.
    enum Scale: CaseIterable {
        case title, priority, headline, icon, body, subhead, label, caption, micro

        var size: CGFloat {
            switch self {
            case .title:    return Material.Typography.title
            case .priority: return Material.Typography.priority
            case .headline: return Material.Typography.headline
            case .icon:     return Material.Typography.icon
            case .body:     return Material.Typography.body
            case .subhead:  return Material.Typography.subhead
            case .label:    return Material.Typography.label
            case .caption:  return Material.Typography.caption
            case .micro:    return Material.Typography.micro
            }
        }

        var textStyle: UIFont.TextStyle {
            switch self {
            case .title, .headline:  return .title1
            case .priority, .icon, .body: return .body
            case .subhead: return .subheadline
            case .label:   return .footnote
            case .caption: return .caption1
            case .micro:   return .caption2
            }
        }

        var weight: UIFont.Weight {
            switch self {
            case .title, .headline, .icon: return .bold
            case .label:                   return .medium
            default:                       return .regular
            }
        }

        var design: UIFontDescriptor.SystemDesign {
            switch self {
            case .title, .headline: return .rounded
            default:                return .default
            }
        }
    }

    /// Resolves a token to a `UIFont` scaled for the given traits (the current
    /// content size category when `traits` is nil).
    static func uiFont(_ scale: Scale, compatibleWith traits: UITraitCollection? = nil) -> UIFont {
        let system = UIFont.systemFont(ofSize: scale.size, weight: scale.weight)
        let base = system.fontDescriptor.withDesign(scale.design)
            .map { UIFont(descriptor: $0, size: scale.size) } ?? system
        return UIFontMetrics(forTextStyle: scale.textStyle)
            .scaledFont(for: base, compatibleWith: traits)
    }

    private static func font(_ scale: Scale) -> Font { Font(uiFont(scale)) }

    // Computed, not stored: each access re-resolves against the current content
    // size category, so the UI reflects a Larger Text change without a relaunch.
    static var title: Font    { font(.title) }
    static var priority: Font { font(.priority) }
    static var headline: Font { font(.headline) }
    static var icon: Font     { font(.icon) }
    static var body: Font     { font(.body) }
    static var bodyMono: Font { font(.body).monospacedDigit() }
    static var subhead: Font  { font(.subhead) }
    static var label: Font    { font(.label) }
    static var caption: Font  { font(.caption) }
    static var micro: Font    { font(.micro) }

    // Widget heroes stay fixed: widget frames cannot grow, so these rely on
    // `minimumScaleFactor` to fit instead.
    static let widgetHero      = Font.system(size: Material.Typography.widgetHero, weight: .heavy)
    static let widgetLargeHero = Font.system(size: Material.Typography.widgetLargeHero, weight: .heavy)
}

// ============================================================
// MARK: - Motion
// ============================================================

enum Motion {

    /// Resolves the effective Reduce Motion state from a view's
    /// `\.accessibilityReduceMotion` environment value.
    ///
    /// The launch-argument override exists because XCUITest cannot toggle the
    /// simulator's Reduce Motion setting, and `\.accessibilityReduceMotion` is
    /// a read-only key path so it cannot be injected at the app root either.
    static func isReduced(_ environmentValue: Bool) -> Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UITestReduceMotion") { return true }
        #endif
        return environmentValue
    }

    /// Drops an animation when Reduce Motion is on, so the state change lands
    /// instantly instead of travelling.
    static func gated(_ animation: Animation?, reduce: Bool) -> Animation? {
        isReduced(reduce) ? nil : animation
    }

    /// Reduce Motion asks for less movement, not less feedback — transitions
    /// fall back to a cross-fade so appearing and disappearing stay legible.
    static func transition(_ transition: AnyTransition, reduce: Bool) -> AnyTransition {
        isReduced(reduce) ? .opacity : transition
    }
}

// ============================================================
// MARK: - Button Styles
// ============================================================

private struct PressEffect: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isPressed: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isPressed ? 0.75 : 1)
            // The dim alone carries the press; only the scale is motion.
            .scaleEffect(isPressed && !Motion.isReduced(reduceMotion) ? 0.97 : 1)
            .animation(Motion.gated(.easeOut(duration: 0.15), reduce: reduceMotion), value: isPressed)
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
    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .font(AppFont.body).fontWeight(.medium)
                .foregroundColor(Material.Text.primary)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .glassEffect(.regular.interactive(), in: Capsule())
        } else {
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
}

// Primary CTA rendered as tinted native Liquid Glass on iOS 26 (glassier than
// .glassProminent), sized to match FilledButtonStyle; solid accent capsule pre-26.
struct PrimaryGlassButtonStyle: ButtonStyle {
    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .font(AppFont.body).fontWeight(.semibold)
                .foregroundColor(Material.Accent.contentPrimary)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .glassEffect(.regular.tint(Material.Accent.primary).interactive(), in: Capsule())
        } else {
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
}

struct GhostButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body).fontWeight(.medium)
            .foregroundColor(Material.Text.secondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .opacity(configuration.isPressed ? 0.4 : 1)
            .animation(Motion.gated(.easeOut(duration: 0.12), reduce: reduceMotion),
                       value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SolidButtonStyle {
    static var solid: SolidButtonStyle { .init() }
}

extension ButtonStyle where Self == FilledButtonStyle {
    static var filled: FilledButtonStyle { .init() }
}

extension ButtonStyle where Self == PrimaryGlassButtonStyle {
    static var primaryGlass: PrimaryGlassButtonStyle { .init() }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { .init() }
}

extension View {
    // Primary call-to-action: accent-tinted Liquid Glass capsule on iOS 26,
    // solid accent capsule on earlier versions. Uses PrimaryGlassButtonStyle
    // rather than .glassProminent because the system style forces a white
    // label, ignoring the dark-mode on-accent color (Accent.contentPrimary).
    func primaryButtonStyle() -> some View {
        self.buttonStyle(.primaryGlass)
    }
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
        .primaryButtonStyle()
        
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    .transition(Motion.transition(
                        .move(edge: .bottom).combined(with: .opacity),
                        reduce: reduceMotion
                    ))
            }
        }
        .animation(Motion.gated(.spring(response: 0.4, dampingFraction: 0.8), reduce: reduceMotion),
                   value: isPresented)
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

/// Tunable cloud-shader parameters. Defaults are the production look;
/// the DEBUG-only Cloud Lab overrides them live to find new values.
struct CloudParams {
    var scale: Double = 1.0     // noise frequency: higher = smaller, busier clouds
    var edgeLow: Double = 0.15  // smoothstep contrast edges: narrower range = punchier
    var edgeHigh: Double = 0.85
    var seed: Float? = nil      // nil → theme.cloudSeed
}

struct NoisyBackgroundView: View {
    let config: NoiseConfig
    let scrollOffset: CGFloat
    var theme: BackgroundTheme = .standard
    var cloudParams: CloudParams = .init()

    private static let noiseImages: [NoiseConfig.NoiseType: UIImage] = makeAllNoise()

    var body: some View {
        ZStack {
            Material.Surface.backdrop.ignoresSafeArea()
            if theme.cloudColors.count == 3 {
                CloudLayer(theme: theme, params: cloudParams)
                    .ignoresSafeArea()
            }
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

    /// Procedural cloud layer — FBM noise shader (Clouds.metal) blending the
    /// theme's three color stops into soft organic shapes. Static; the per-theme
    /// seed gives each preset a distinct cloud arrangement.
    private struct CloudLayer: View {
        let theme: BackgroundTheme
        var params: CloudParams = .init()

        var body: some View {
            let colors = theme.cloudColors
            let seed = params.seed ?? theme.cloudSeed
            let scale = Float(params.scale)
            let edgeLow = Float(params.edgeLow)
            let edgeHigh = Float(params.edgeHigh)
            Color.white
                .visualEffect { content, proxy in
                    content.colorEffect(
                        ShaderLibrary.clouds(
                            .float2(proxy.size),
                            .color(colors[0]),
                            .color(colors[1]),
                            .color(colors[2]),
                            .float(scale),
                            .float(seed),
                            .float(edgeLow),
                            .float(edgeHigh)
                        )
                    )
                }
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
// MARK: - Widget Background
// ============================================================

/// Backdrop for the home-screen widget families, matching the palette of the
/// background theme the user picked in the app, shifted toward the temperature
/// of the hour in `date`. `standard` keeps the neutral surface that makes the
/// widget read as a card on the wallpaper.
struct WidgetBackground: View {
    let theme: BackgroundTheme
    var date: Date = .now

    var body: some View {
        let colors = theme.widgetMeshColors(at: date)
        if colors.count == 9 {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    .init(0, 0),    .init(0.5, 0),     .init(1, 0),
                    .init(0, 0.5),  .init(0.6, 0.45),  .init(1, 0.5),
                    .init(0, 1),    .init(0.5, 1),     .init(1, 1)
                ],
                colors: colors
            )
        } else {
            Material.Surface.primary
        }
    }
}

// ============================================================
// MARK: - Bottom CTA
// ============================================================

/// Bottom-anchored call-to-action block: a full-width primary button plus an
/// optional secondary (ghost) action below it. Attach with
/// `.safeAreaInset(edge: .bottom) { BottomCTA(...) }` so scrolling content
/// stays clear of it.
struct BottomCTA: View {
    let title: String
    var systemImage: String? = nil
    var identifier: String? = nil
    let action: () -> Void
    var secondaryTitle: String? = nil
    var secondaryIdentifier: String? = nil
    var secondaryAction: () -> Void = {}

    var body: some View {
        VStack(spacing: 4) {
            Button(action: action) {
                HStack(spacing: 8) {
                    if let systemImage {
                        Image(systemName: systemImage)
                    }
                    Text(title)
                }
                .frame(maxWidth: .infinity, minHeight: 24)
            }
            .primaryButtonStyle()
            .accessibilityIdentifier(identifier ?? "")

            if let secondaryTitle {
                Button(action: secondaryAction) {
                    Text(secondaryTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.ghost)
                .accessibilityIdentifier(secondaryIdentifier ?? "")
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 12)
        .padding(.bottom, 8)
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

// MARK: - Settings Section Container

/// Where a row sits in its settings section, which decides the corners it
/// rounds.
enum SettingsRowPosition {
    case top, middle, bottom, single

    fileprivate var topRadius: CGFloat {
        (self == .top || self == .single) ? Material.Shape.container : 0
    }

    fileprivate var bottomRadius: CGFloat {
        (self == .bottom || self == .single) ? Material.Shape.container : 0
    }
}

extension View {
    /// Gives a settings section the same panel treatment as the onboarding
    /// container. A grouped `List` draws its own section background and will
    /// not take a custom radius, so each row paints the slice of the container
    /// that belongs to it and only the outer corners are rounded.
    func settingsRowBackground(_ position: SettingsRowPosition) -> some View {
        listRowBackground(
            UnevenRoundedRectangle(
                topLeadingRadius: position.topRadius,
                bottomLeadingRadius: position.bottomRadius,
                bottomTrailingRadius: position.bottomRadius,
                topTrailingRadius: position.topRadius,
                style: .continuous
            )
            .fill(Material.Surface.secondary)
        )
    }
}

