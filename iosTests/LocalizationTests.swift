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
        "en", "es", "es-MX", "fr", "de", "nl", "pt", "ca", "ca-ES",
    ]

    /// Locales carrying their own translations, as opposed to the Spanish
    /// mirrors. Shared so a new locale cannot be added to one test but missed
    /// in another.
    static let translatedLocales = ["es", "es-MX", "fr", "de", "nl", "pt", "ca", "ca-ES"]

    /// Keys chosen because they appear on the first screens a user sees and
    /// because their translations differ from English in every target language.
    static let anchorKeys = ["Settings", "Cancel", "What's on your mind?"]

    /// Every `AppShortcut` utterance declared by `MirandaShortcuts`, in the
    /// `${applicationName}` form the catalog uses.
    static let siriPhrases = [
        "Capture a note in ${applicationName}",
        "Add a note to ${applicationName}",
        "Note something in ${applicationName}",
        "Capture this in ${applicationName}",
        "Add this to ${applicationName}",
        "Add to ${applicationName}",
        "Remove all priorities in ${applicationName}",
        "Add priority to ${applicationName}",
        "Set my priority in ${applicationName}",
    ]

    /// Visible and spoken strings used while collecting intent input.
    static let siriIntentKeys = [
        "What would you like to add to Miranda?",
    ]

    @Test func bundleShipsEveryLocalization() {
        let available = Set(Bundle.main.localizations)
        for code in Self.shippingLocalizations {
            #expect(
                available.contains(code),
                "\(code) is missing from the built bundle. Add it to knownRegions in project.pbxproj and localize the string catalogs. Bundle has: \(Bundle.main.localizations.sorted())"
            )
        }
    }

    @Test(arguments: Self.translatedLocales)
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

    /// Peninsular terms and the Mexican wording that must replace them.
    ///
    /// A device set to Spanish (Mexico) already resolves `es` by falling back on
    /// the language, so shipping `es-MX` is only worth the extra locale if the
    /// copy actually differs. These pairs are the reason it exists.
    static let mexicanRewordings: [(key: String, peninsular: String, mexican: String)] = [
        ("Add your first note", "Añade", "Agrega"),
        ("Count how many pens you have ✍️", "bolis", "plumas"),
        ("Long press, then drag up or down to reorder", "pulsado", "presionado"),
        ("Say 'potato' in 3 different accents 🥔", "patata", "papa"),
    ]

    @Test func mexicanSpanishIsDifferentiatedFromPeninsular() throws {
        let mexican = try #require(localizedBundle(for: "es-MX"))
        let spanish = try #require(localizedBundle(for: "es"))

        for (key, peninsular, expected) in Self.mexicanRewordings {
            let mxValue = mexican.localizedString(forKey: key, value: nil, table: nil)
            let esValue = spanish.localizedString(forKey: key, value: nil, table: nil)

            #expect(
                mxValue != esValue,
                "'\(key)' is identical in es and es-MX, so es-MX adds nothing over the es fallback"
            )
            #expect(
                mxValue.localizedCaseInsensitiveContains(expected),
                "'\(key)' in es-MX should use '\(expected)': \(mxValue)"
            )
            #expect(
                !mxValue.localizedCaseInsensitiveContains(peninsular),
                "'\(key)' in es-MX still uses the peninsular '\(peninsular)': \(mxValue)"
            )
            #expect(
                esValue.localizedCaseInsensitiveContains(peninsular),
                "'\(key)' no longer uses '\(peninsular)' in es — update mexicanRewordings"
            )
        }
    }

    /// Spanish wording and the Catalan that must replace it.
    ///
    /// Catalan shipped as a byte-for-byte copy of Spanish for several releases:
    /// the store listing was Catalan while the app itself spoke Spanish. These
    /// pairs fail if anything ever refills `ca` from `es` again.
    static let catalanRewordings: [(key: String, spanish: String, catalan: String)] = [
        ("Settings", "Ajustes", "Configuració"),
        ("Cancel", "Cancelar", "Cancel·la"),
        ("Save", "Guardar", "Desa"),
        ("What's on your mind?", "¿Qué tienes en mente?", "Què tens al cap?"),
    ]

    @Test(arguments: ["ca", "ca-ES"])
    func catalanIsTranslatedNotMirroredFromSpanish(code: String) throws {
        let catalan = try #require(localizedBundle(for: code))
        let spanish = try #require(localizedBundle(for: "es"))

        for (key, spanishValue, expected) in Self.catalanRewordings {
            let caValue = catalan.localizedString(forKey: key, value: nil, table: nil)
            let esValue = spanish.localizedString(forKey: key, value: nil, table: nil)

            #expect(
                caValue == expected,
                "'\(key)' in \(code) should be '\(expected)': \(caValue)"
            )
            #expect(
                caValue != esValue,
                "'\(key)' in \(code) is identical to Spanish — Catalan is being mirrored again"
            )
            #expect(
                esValue == spanishValue,
                "'\(key)' no longer reads '\(spanishValue)' in es — update catalanRewordings"
            )
        }
    }

    @Test func permissionPromptsAreTranslated() throws {
        let keys = ["NSMicrophoneUsageDescription", "NSSpeechRecognitionUsageDescription"]

        for code in Self.translatedLocales {
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

    /// Siri phrases live in their own `AppShortcuts` table — they are not
    /// extracted into `Localizable.xcstrings`, so an app can be fully localized
    /// and still only respond to English speech.
    @Test(arguments: Self.translatedLocales)
    func siriPhrasesAreTranslated(code: String) throws {
        let bundle = try #require(localizedBundle(for: code))

        for phrase in Self.siriPhrases {
            let value = bundle.localizedString(
                forKey: phrase, value: nil, table: "AppShortcuts"
            )
            #expect(
                value != phrase,
                "Siri phrase '\(phrase)' is untranslated in \(code)"
            )
            // The App Intents validator rejects any utterance that drops it.
            #expect(
                value.contains("${applicationName}"),
                "Siri phrase '\(phrase)' in \(code) lost ${applicationName}: \(value)"
            )
        }
    }

    @Test(arguments: Self.translatedLocales)
    func siriIntentStringsAreTranslated(code: String) throws {
        let bundle = try #require(localizedBundle(for: code))

        for key in Self.siriIntentKeys {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)
            #expect(value != key, "Siri intent string '\(key)' is untranslated in \(code)")
        }
    }

    @Test(arguments: Self.translatedLocales)
    func notificationTitlesAreTranslated(code: String) throws {
        let bundle = try #require(localizedBundle(for: code))

        for key in NotificationTitleTests.titleKeys {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)
            #expect(value != key, "\(key) is missing an \(code) translation")
        }
    }

    private func localizedBundle(for code: String) -> Bundle? {
        guard let url = Bundle.main.url(forResource: code, withExtension: "lproj") else {
            return nil
        }
        return Bundle(url: url)
    }
}
