import Testing
import SwiftUI
@testable import ios

struct AppIconOptionTests {

    @Test func hasSevenOptionsInDisplayOrder() {
        #expect(AppIconOption.allCases == [.default, .dark, .silhouette, .bloom, .meadow, .dusk, .turtle])
    }

    @Test func onlyDefaultUsesPrimaryIcon() {
        #expect(AppIconOption.default.iconName(for: .light) == nil)
        #expect(AppIconOption.default.iconName(for: .dark) == nil)
        for option in AppIconOption.allCases where option != .default {
            #expect(option.iconName(for: .light) != nil, "\(option) must map to a light alternate asset")
            #expect(option.iconName(for: .dark) != nil, "\(option) must map to a dark alternate asset")
        }
    }

    @Test func fixedOptionsIgnoreAppearance() {
        #expect(AppIconOption.dark.iconName(for: .light) == "AppIconDark")
        #expect(AppIconOption.dark.iconName(for: .dark) == "AppIconDark")
        #expect(AppIconOption.silhouette.iconName(for: .light) == "AppIconSilhouette")
        #expect(AppIconOption.silhouette.iconName(for: .dark) == "AppIconSilhouette")
        #expect(AppIconOption.turtle.iconName(for: .light) == "AppIconTurtle")
        #expect(AppIconOption.turtle.iconName(for: .dark) == "AppIconTurtle")
    }

    @Test func colorThemesResolveToAppearanceSpecificAssets() {
        #expect(AppIconOption.bloom.iconName(for: .light) == "AppIconBloomLight")
        #expect(AppIconOption.bloom.iconName(for: .dark) == "AppIconBloomDark")
        #expect(AppIconOption.meadow.iconName(for: .light) == "AppIconMeadowLight")
        #expect(AppIconOption.meadow.iconName(for: .dark) == "AppIconMeadowDark")
        #expect(AppIconOption.dusk.iconName(for: .light) == "AppIconDuskLight")
        #expect(AppIconOption.dusk.iconName(for: .dark) == "AppIconDuskDark")
    }

    @Test func colorThemesDifferBetweenLightAndDark() {
        for option in [AppIconOption.bloom, .meadow, .dusk] {
            #expect(option.iconName(for: .light) != option.iconName(for: .dark))
        }
    }

    @Test func iconNamesAreUniqueWithinEachAppearance() {
        for scheme in [ColorScheme.light, .dark] {
            let names = AppIconOption.allCases.compactMap { $0.iconName(for: scheme) }
            #expect(Set(names).count == names.count)
        }
    }

    @Test func previewAssetNamesAreUniqueAndNonEmpty() {
        let previews = AppIconOption.allCases.map { $0.previewAssetName }
        #expect(Set(previews).count == previews.count)
        #expect(previews.allSatisfy { !$0.isEmpty })
    }

    @Test func displayNamesAreNonEmpty() {
        for option in AppIconOption.allCases {
            #expect(!option.displayName.isEmpty)
        }
    }
}
