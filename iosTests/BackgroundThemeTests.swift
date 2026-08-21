import Foundation
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

    @Test func themesInDisplayOrder() {
        #expect(BackgroundTheme.allCases == [.standard, .bloom, .meadow, .dusk, .nostalgia])
    }

    /// The Settings row fits four swatches beside its label; a fifth wraps the
    /// label. Nostalgia stays implemented but out of the picker until that row
    /// gets a layout that scales.
    @Test func selectableFitsTheSettingsRow() {
        #expect(BackgroundTheme.selectable == [.standard, .bloom, .meadow, .dusk])
        #expect(BackgroundTheme.selectable.count <= 4)
        #expect(!BackgroundTheme.selectable.contains(.nostalgia))
        #expect(BackgroundTheme.selectable.allSatisfy { BackgroundTheme.allCases.contains($0) })
    }

    /// Nostalgia is a teal ground with a warm accent, so its peak stop has to
    /// stay clearly apart from the two stops that cover most of the field —
    /// otherwise the accent vanishes and the theme reads as a flat wash.
    @Test func nostalgiaAccentDiffersFromItsGround() {
        let stops = BackgroundTheme.nostalgia.cloudStops
        #expect(stops.count == 3)
        #expect(stops[2].light != stops[0].light)
        #expect(stops[2].light != stops[1].light)
        #expect(stops[2].dark != stops[0].dark)
        #expect(stops[2].dark != stops[1].dark)
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

    @Test func widgetMeshColors() {
        // The mesh is now resolved for a moment in time, but its shape must
        // hold at every hour, not just the one the test happens to run at.
        for hour in [2, 10, 18] {
            let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
            #expect(BackgroundTheme.standard.widgetMeshColors(at: date).isEmpty)
            for theme in BackgroundTheme.allCases where theme != .standard {
                #expect(theme.widgetMeshColors(at: date).count == 9,
                        "\(theme) must supply 9 colors for a 3x3 mesh at hour \(hour)")
            }
        }
    }

    /// The layout indexes into `cloudColors`, so it must stay inside those three
    /// stops and keep the accent scarce.
    @Test func widgetMeshLayout() {
        let layout = BackgroundTheme.widgetMeshLayout
        #expect(layout.count == 9)
        #expect(layout.allSatisfy { (0..<3).contains($0) })
        #expect(Set(layout) == [0, 1, 2], "every cloud stop should appear in the mesh")
        #expect(layout.filter { $0 == 2 }.count == 2, "the accent stop should stay scarce")
    }

    // MARK: - App Group storage

    /// Scratch suite so tests never touch the real App Group container.
    private func scratchDefaults(_ name: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: "BackgroundThemeTests.\(name)")!
        defaults.removePersistentDomain(forName: "BackgroundThemeTests.\(name)")
        return defaults
    }

    @Test func backgroundThemeReadsFromSharedStore() {
        let defaults = scratchDefaults(#function)

        #expect(SharedCardManager.backgroundTheme(from: defaults) == .standard)

        defaults.set(BackgroundTheme.bloom.rawValue, forKey: SharedCardManager.backgroundThemeKey)
        #expect(SharedCardManager.backgroundTheme(from: defaults) == .bloom)

        defaults.set("not-a-theme", forKey: SharedCardManager.backgroundThemeKey)
        #expect(SharedCardManager.backgroundTheme(from: defaults) == .standard)
    }

    @Test func backgroundThemeMigration() {
        let key = SharedCardManager.backgroundThemeKey

        // Legacy pick moves into the shared suite.
        let legacy = scratchDefaults("legacy")
        let shared = scratchDefaults("shared")
        legacy.set(BackgroundTheme.dusk.rawValue, forKey: key)
        #expect(SharedCardManager.migrateBackgroundTheme(from: legacy, to: shared))
        #expect(SharedCardManager.backgroundTheme(from: shared) == .dusk)

        // Running again is a no-op — the shared value already wins.
        legacy.set(BackgroundTheme.bloom.rawValue, forKey: key)
        #expect(SharedCardManager.migrateBackgroundTheme(from: legacy, to: shared) == false)
        #expect(SharedCardManager.backgroundTheme(from: shared) == .dusk)

        // Nothing to migrate when the user never picked a theme.
        let emptyLegacy = scratchDefaults("emptyLegacy")
        let emptyShared = scratchDefaults("emptyShared")
        #expect(SharedCardManager.migrateBackgroundTheme(from: emptyLegacy, to: emptyShared) == false)
        #expect(emptyShared.string(forKey: key) == nil)
    }
}
