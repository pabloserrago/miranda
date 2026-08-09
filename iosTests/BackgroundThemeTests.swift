import Testing
@testable import ios

struct BackgroundThemeTests {

    @Test func rawValueRoundTrip() {
        for theme in BackgroundTheme.allCases {
            #expect(BackgroundTheme(rawValue: theme.rawValue) == theme)
        }
    }

    @Test func defaultIsStandard() {
        #expect(BackgroundTheme(rawValue: "standard") == .standard)
    }

    @Test func cloudColorStops() {
        #expect(BackgroundTheme.standard.cloudColors.isEmpty)
        for theme in BackgroundTheme.allCases where theme != .standard {
            #expect(theme.cloudColors.count == 3, "\(theme) must supply exactly 3 cloud color stops")
        }
    }

    @Test func swatchColors() {
        for theme in BackgroundTheme.allCases {
            #expect(theme.swatchColors.count == 3, "\(theme) must supply 3 swatch colors")
        }
    }
}
