import XCTest

/// Launches the app under a non-English system language and asserts translated
/// copy actually reaches the screen.
///
/// A bundle can contain an `es.lproj` and still render English if the catalog
/// entries are empty, so these tests check rendered labels rather than
/// resource presence.
final class LocalizationUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testHomeAndSettingsAreSpanishWhenDeviceIsSpanish() throws {
        let app = launch(language: "es", locale: "es_ES")

        // The title is the untranslated brand name, so assert on the settings
        // sheet instead — its section header is real translated copy.
        openSettings(in: app)

        XCTAssertTrue(
            app.staticTexts["Capturar"].waitForExistence(timeout: 3),
            "settings section header is not Spanish; tree:\n\(app.debugDescription)"
        )
        XCTAssertFalse(
            app.staticTexts["Capture"].exists,
            "English copy leaked into the Spanish build; tree:\n\(app.debugDescription)"
        )
    }

    @MainActor
    func testSettingsAreFrenchWhenDeviceIsFrench() throws {
        let app = launch(language: "fr", locale: "fr_FR")
        openSettings(in: app)

        XCTAssertTrue(
            app.staticTexts["Capturer"].waitForExistence(timeout: 3),
            "settings section header is not French; tree:\n\(app.debugDescription)"
        )
        XCTAssertFalse(
            app.staticTexts["Capture"].exists,
            "English copy leaked into the French build; tree:\n\(app.debugDescription)"
        )
    }

    /// Catalan has no translations of its own — it mirrors Spanish. Verify the
    /// mirror reaches the UI instead of falling back to English.
    @MainActor
    func testCatalanFallsBackToSpanishNotEnglish() throws {
        let app = launch(language: "ca", locale: "ca_ES")
        openSettings(in: app)

        XCTAssertTrue(
            app.staticTexts["Capturar"].waitForExistence(timeout: 3),
            "Catalan did not mirror Spanish; tree:\n\(app.debugDescription)"
        )
    }

    @MainActor
    private func launch(language: String, locale: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITestSeedNotes",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ]
        app.launch()
        return app
    }

    @MainActor
    private func openSettings(in app: XCUIApplication) {
        let settingsButton = app.buttons["settings-button"]
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: 5),
            "settings button missing; tree:\n\(app.debugDescription)"
        )
        settingsButton.tap()
    }
}
