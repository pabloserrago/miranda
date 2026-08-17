import Foundation
import Testing
@testable import ios

/// Guards that the shipped bundle actually contains the translated resources.
///
/// The app previously had string catalogs with an `en` localization only, so
/// switching the device to Spanish silently fell back to English. These tests
/// fail on that state rather than letting it reach the App Store.
struct LocalizationTests {

    /// Every locale the app claims to support.
    static let shippingLocalizations = [
        "en", "es", "fr", "de", "nl", "pt", "ca", "ca-ES", "eu", "gl",
    ]

    /// Keys chosen because they appear on the first screens a user sees and
    /// because their translations differ from English in every target language.
    static let anchorKeys = ["Settings", "Cancel", "What's on your mind?"]

    @Test func bundleShipsEveryLocalization() {
        let available = Set(Bundle.main.localizations)
        for code in Self.shippingLocalizations {
            #expect(
                available.contains(code),
                "\(code) is missing from the built bundle. Add it to knownRegions in project.pbxproj and localize the string catalogs. Bundle has: \(Bundle.main.localizations.sorted())"
            )
        }
    }

    @Test(arguments: ["es", "fr", "de", "nl", "pt"])
    func anchorStringsAreTranslated(code: String) throws {
        let bundle = try #require(
            localizedBundle(for: code),
            "no \(code).lproj in the built bundle"
        )

        for key in Self.anchorKeys {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)

            #expect(
                value != key,
                "'\(key)' is untranslated in \(code) — it resolved to the English source"
            )
            #expect(
                !value.hasPrefix("[\(code)]"),
                "'\(key)' in \(code) is a translate.py --dry-run placeholder: \(value)"
            )
        }
    }

    /// The Spanish-mirroring locales must resolve, not fall through to English.
    @Test(arguments: ["ca", "eu", "gl"])
    func spanishMirroringLocalesResolve(code: String) throws {
        let mirrored = try #require(localizedBundle(for: code))
        let spanish = try #require(localizedBundle(for: "es"))

        for key in Self.anchorKeys {
            let value = mirrored.localizedString(forKey: key, value: nil, table: nil)
            let esValue = spanish.localizedString(forKey: key, value: nil, table: nil)
            #expect(value == esValue, "'\(key)' in \(code) should mirror the Spanish value")
        }
    }

    @Test func permissionPromptsAreTranslated() throws {
        let keys = ["NSMicrophoneUsageDescription", "NSSpeechRecognitionUsageDescription"]

        for code in ["es", "fr", "de", "nl", "pt"] {
            let bundle = try #require(localizedBundle(for: code))
            for key in keys {
                let value = bundle.localizedString(
                    forKey: key, value: nil, table: "InfoPlist"
                )
                #expect(value != key, "\(key) is missing an \(code) translation")
                #expect(
                    !value.hasPrefix("["),
                    "\(key) in \(code) is still a placeholder: \(value)"
                )
            }
        }
    }

    private func localizedBundle(for code: String) -> Bundle? {
        guard let url = Bundle.main.url(forResource: code, withExtension: "lproj") else {
            return nil
        }
        return Bundle(url: url)
    }
}
