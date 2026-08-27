import Testing
import SwiftUI
@testable import ios

struct AppIconOptionTests {

    @Test func hasEightOptionsInDisplayOrder() {
        #expect(AppIconOption.allCases == [.default, .dark, .silhouette, .bloom, .meadow, .dusk, .turtle, .hero])
    }

    @Test func selectableOptionsHideRetiredColorIcons() {
        #expect(AppIconOption.selectableCases == [.default, .dark, .silhouette, .turtle, .hero])
        #expect(!AppIconOption.selectableCases.contains(.bloom))
        #expect(!AppIconOption.selectableCases.contains(.meadow))
        #expect(!AppIconOption.selectableCases.contains(.dusk))
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
        #expect(AppIconOption.hero.iconName(for: .light) == "AppIconHero")
        #expect(AppIconOption.hero.iconName(for: .dark) == "AppIconHero")
    }

    @Test func colorThemesResolveToAppearanceSpecificAssets() {
        #expect(AppIconOption.bloom.iconName(for: .light) == "AppIconBloomLight")
        #expect(AppIconOption.bloom.iconName(for: .dark) == "AppIconBloomDark")
        #expect(AppIconOption.meadow.iconName(for: .light) == "AppIconMeadowLight")
        #expect(AppIconOption.meadow.iconName(for: .dark) == "AppIconMeadowDark")
        #expect(AppIconOption.dusk.iconName(for: .light) == "AppIconDuskLight")
        #expect(AppIconOption.dusk.iconName(for: .dark) == "AppIconDuskDark")
        #expect(AppIconOption.turtle.iconName(for: .light) == "AppIconTurtleLight")
        #expect(AppIconOption.turtle.iconName(for: .dark) == "AppIconTurtleDark")
    }

    @Test func colorThemesDifferBetweenLightAndDark() {
        for option in [AppIconOption.bloom, .meadow, .dusk, .turtle] {
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
