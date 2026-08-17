import Foundation
import Testing
@testable import ios

/// Scratch suite so tests never touch the real App Group container.
private func makeTestDefaults() -> UserDefaults {
    let suite = "com.test.AnalyticsIdentity.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return defaults
}

// MARK: - Install identifier

struct AnalyticsInstallIDTests {

    @Test func resolveInstallIDReusesStoredUUID() {
        let existing = UUID().uuidString

        #expect(Analytics.resolveInstallID(stored: existing) == existing)
    }

    @Test func resolveInstallIDReplacesMissingOrMalformed() {
        for stored in [nil, "", "not-a-uuid", "1234"] as [String?] {
            let resolved = Analytics.resolveInstallID(stored: stored)

            #expect(UUID(uuidString: resolved) != nil)
            #expect(resolved != stored)
        }
    }

    @Test func installIDPersistsAcrossCalls() {
        let defaults = makeTestDefaults()

        let first = Analytics.installID(in: defaults)
        let second = Analytics.installID(in: defaults)

        #expect(first == second)
        #expect(defaults.string(forKey: Analytics.installIDKey) == first)
    }

    @Test func installIDIsDistinctPerContainer() {
        // Two installs must never collide, which is what makes per-user
        // funnel cohorts countable.
        #expect(Analytics.installID(in: makeTestDefaults())
                != Analytics.installID(in: makeTestDefaults()))
    }
}

// MARK: - Upload body

struct AnalyticsEventBodyTests {

    @Test func eventBodyIncludesInstallID() throws {
        let installID = UUID().uuidString

        let body = Analytics.eventBody(
            event: "app_opened",
            properties: ["has_emoji": true],
            appVersion: "1.1",
            language: "en",
            installID: installID)

        #expect(body["install_id"] as? String == installID)
        #expect(body["event"] as? String == "app_opened")
        #expect(body["app_version"] as? String == "1.1")
        #expect(body["language"] as? String == "en")
        #expect(JSONSerialization.isValidJSONObject(body))

        let properties = try #require(body["properties"] as? [String: Any])
        #expect(properties["has_emoji"] as? Bool == true)
    }
}

// MARK: - Widget inventory

struct AnalyticsWidgetInventoryTests {

    @Test func signatureIsSortedDeduplicatedAndStable() {
        let signature = Analytics.widgetInventorySignature(
            families: ["systemMedium", "systemSmall", "systemMedium"])

        #expect(signature == "systemMedium,systemSmall")
        // Order of arrival must not produce a second, spurious change event.
        #expect(signature == Analytics.widgetInventorySignature(
            families: ["systemSmall", "systemMedium"]))
    }

    @Test func signatureDistinguishesNoWidgetsFromSome() {
        #expect(Analytics.widgetInventorySignature(families: []) == "none")
        #expect(Analytics.widgetInventorySignature(families: ["accessoryRectangular"])
                == "accessoryRectangular")
    }

    @Test func inventoryChangeIsReportedOnceUntilItChanges() {
        let defaults = makeTestDefaults()

        #expect(Analytics.consumeWidgetInventoryChange(signature: "none", in: defaults))
        #expect(Analytics.consumeWidgetInventoryChange(signature: "none", in: defaults) == false)
        #expect(Analytics.consumeWidgetInventoryChange(signature: "systemSmall", in: defaults))
        #expect(Analytics.consumeWidgetInventoryChange(signature: "systemSmall", in: defaults) == false)
    }
}

// MARK: - Widget attribution

struct AnalyticsWidgetDestinationTests {

    @Test func widgetDestinationClassifiesDeepLinks() {
        let cardURL = URL(string: "miranda://card/\(UUID().uuidString)")!

        #expect(Analytics.widgetDestination(for: cardURL) == "card")
        #expect(Analytics.widgetDestination(for: URL(string: "miranda://capture")!) == "capture")
    }

    @Test func widgetDestinationIgnoresForeignURLs() {
        #expect(Analytics.widgetDestination(for: URL(string: "https://miranda.app")!) == nil)
        #expect(Analytics.widgetDestination(for: URL(string: "miranda://settings")!) == nil)
    }
}
