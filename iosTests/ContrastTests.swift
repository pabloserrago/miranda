import Testing
import SwiftUI
import UIKit
@testable import ios

/// WCAG 2.1 contrast ratios for every `Material` foreground/background pair the
/// app renders text or meaningful icons on, in both interface styles.
///
/// Purely decorative boundaries (glass card borders, gradient stops, the fake
/// iOS status bar in the widget preview) are excluded: WCAG 1.4.11 applies to
/// visuals required to identify a control, and those carry no information.
struct ContrastTests {

    /// WCAG AA for body text.
    private let textMinimum = 4.5
    /// WCAG AA for icons and other non-text UI.
    private let uiMinimum = 3.0

    private struct Pair {
        let name: String
        let foreground: Color
        let background: Color
    }

    // MARK: WCAG math

    /// WCAG 2.1 relative luminance.
    private func luminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        func channel(_ c: CGFloat) -> Double {
            let v = Double(c)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    private func ratio(_ foreground: UIColor, _ background: UIColor) -> Double {
        let l1 = luminance(foreground)
        let l2 = luminance(background)
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }

    /// Flattens a dynamic `Material` token to the concrete color it renders as
    /// in one interface style.
    private func resolve(_ color: Color, _ style: UIUserInterfaceStyle) -> UIColor {
        UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }

    /// Blends a translucent foreground onto its background. Text tokens are
    /// expressed as ink over the surface, so the rendered colour — not the raw
    /// token — is what WCAG measures.
    private func composite(_ foreground: UIColor, over background: UIColor) -> UIColor {
        var fr: CGFloat = 0, fg: CGFloat = 0, fb: CGFloat = 0, fa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        foreground.getRed(&fr, green: &fg, blue: &fb, alpha: &fa)
        background.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        guard fa < 1 else { return foreground }
        return UIColor(red:   fa * fr + (1 - fa) * br,
                       green: fa * fg + (1 - fa) * bg,
                       blue:  fa * fb + (1 - fa) * bb,
                       alpha: 1)
    }

    private func check(_ pairs: [Pair], minimum: Double) {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let styleName = style == .light ? "light" : "dark"
            for pair in pairs {
                let background = resolve(pair.background, style)
                let value = ratio(composite(resolve(pair.foreground, style), over: background),
                                  background)
                #expect(
                    value >= minimum,
                    "\(pair.name) in \(styleName): \(String(format: "%.2f", value)):1 is below \(minimum):1"
                )
            }
        }
    }

    // MARK: Text on surfaces

    @Test func textOnSurfaces() {
        let surfaces: [(String, Color)] = [
            ("backdrop",  Material.Surface.backdrop),
            ("primary",   Material.Surface.primary),
            ("secondary", Material.Surface.secondary),
        ]
        let foregrounds: [(String, Color)] = [
            ("Text.primary",   Material.Text.primary),
            ("Text.secondary", Material.Text.secondary),
            ("Text.tertiary",  Material.Text.tertiary),
            ("Text.accent",    Material.Text.accent),
        ]
        check(
            surfaces.flatMap { surface in
                foregrounds.map { foreground in
                    Pair(name: "\(foreground.0) on Surface.\(surface.0)",
                         foreground: foreground.1,
                         background: surface.1)
                }
            },
            minimum: textMinimum
        )
    }

    // MARK: Text on control fills

    @Test func textOnControlFills() {
        let fills: [(String, Color)] = [
            ("fillPrimary",   Material.Control.fillPrimary),
            ("fillSecondary", Material.Control.fillSecondary),
            ("fillTertiary",  Material.Control.fillTertiary),
        ]
        check(
            fills.flatMap { fill in
                [
                    Pair(name: "Text.primary on Control.\(fill.0)",
                         foreground: Material.Text.primary, background: fill.1),
                    Pair(name: "Text.secondary on Control.\(fill.0)",
                         foreground: Material.Text.secondary, background: fill.1),
                ]
            },
            minimum: textMinimum
        )
    }

    // MARK: Text on inverted and accent fills

    @Test func textOnInvertedFills() {
        check([
            // SolidButtonStyle label.
            Pair(name: "Accent.contentPrimary on Accent.primary",
                 foreground: Material.Accent.contentPrimary,
                 background: Material.Accent.primary),
            // Widget note button: label on a Text.primary capsule.
            Pair(name: "Text.inverse on Text.primary",
                 foreground: Material.Text.inverse,
                 background: Material.Text.primary),
        ], minimum: textMinimum)
    }

    // MARK: Destructive signalling

    @Test func destructiveTextOnSurfaces() {
        check([
            Pair(name: "Status.error on Surface.backdrop",
                 foreground: Material.Status.error,
                 background: Material.Surface.backdrop),
            Pair(name: "Status.error on Surface.primary",
                 foreground: Material.Status.error,
                 background: Material.Surface.primary),
        ], minimum: textMinimum)
    }

    // MARK: Widget text over the themed background

    /// The widget's mesh background blends the theme's cloud stops, so every
    /// stop has to carry the widget's text on its own. `Text.tertiary` is absent
    /// deliberately: it measures below AA on the mid and accent stops, which is
    /// why the widget's "+ Note" link uses `Text.secondary`.
    @Test func widgetTextOnThemeBackgrounds() {
        let foregrounds: [(String, Color)] = [
            ("Text.primary",   Material.Text.primary),
            ("Text.secondary", Material.Text.secondary),
        ]
        let pairs = BackgroundTheme.allCases.flatMap { theme in
            theme.cloudColors.enumerated().flatMap { index, stop in
                foregrounds.map { foreground in
                    Pair(name: "\(foreground.0) on \(theme) mesh stop \(index)",
                         foreground: foreground.1,
                         background: stop)
                }
            }
        }
        check(pairs, minimum: textMinimum)
    }

    // MARK: Meaningful icons

    @Test func iconsOnSurfaces() {
        check([
            Pair(name: "Icon.primary on Surface.secondary",
                 foreground: Material.Icon.primary,
                 background: Material.Surface.secondary),
            Pair(name: "Icon.muted on Surface.backdrop",
                 foreground: Material.Icon.muted,
                 background: Material.Surface.backdrop),
        ], minimum: uiMinimum)
    }
}
