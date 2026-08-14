import Testing
import SwiftUI
import UIKit
@testable import ios

/// Every in-app type token must honour the Larger Text setting while still
/// rendering at its documented `Material.Typography` size by default.
///
/// Widget hero fonts are deliberately absent from `AppFont.Scale`: widget
/// layout is size-constrained and scales via `minimumScaleFactor` instead.
struct AppFontScalingTests {

    private let standard = UITraitCollection(preferredContentSizeCategory: .large)
    private let ax5 = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

    @Test func defaultSizeMatchesTheDocumentedScale() {
        for scale in AppFont.Scale.allCases {
            let font = AppFont.uiFont(scale, compatibleWith: standard)
            #expect(
                font.pointSize == scale.size,
                "\(scale) renders at \(font.pointSize)pt at the default content size, expected \(scale.size)pt"
            )
        }
    }

    @Test func everyTokenGrowsAtLargestAccessibilitySize() {
        for scale in AppFont.Scale.allCases {
            let base = AppFont.uiFont(scale, compatibleWith: standard).pointSize
            let scaled = AppFont.uiFont(scale, compatibleWith: ax5).pointSize
            #expect(
                scaled > base,
                "\(scale) does not scale: \(base)pt at default, \(scaled)pt at AX5"
            )
        }
    }

    @Test func scalingIsMonotonicAcrossContentSizes() {
        let categories: [UIContentSizeCategory] = [
            .extraSmall, .small, .medium, .large, .extraLarge, .extraExtraLarge,
            .accessibilityMedium, .accessibilityLarge, .accessibilityExtraExtraExtraLarge,
        ]
        for scale in AppFont.Scale.allCases {
            let sizes = categories.map {
                AppFont.uiFont(scale, compatibleWith: UITraitCollection(preferredContentSizeCategory: $0)).pointSize
            }
            #expect(
                sizes == sizes.sorted(),
                "\(scale) does not grow monotonically across content sizes: \(sizes)"
            )
        }
    }

    @Test func roundedTokensKeepTheirDesign() {
        let roundedFamily = UIFont.systemFont(ofSize: 17).fontDescriptor
            .withDesign(.rounded)
            .map { UIFont(descriptor: $0, size: 17).familyName }
        for scale in AppFont.Scale.allCases where scale.design == .rounded {
            let font = AppFont.uiFont(scale, compatibleWith: ax5)
            #expect(
                font.familyName == roundedFamily,
                "\(scale) lost its rounded design after scaling: \(font.familyName)"
            )
        }
    }
}
