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
        #expect(BackgroundTheme.standard.widgetMeshColors.isEmpty)
        for theme in BackgroundTheme.allCases where theme != .standard {
            #expect(theme.widgetMeshColors.count == 9,
                    "\(theme) must supply 9 colors for a 3x3 mesh")
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
