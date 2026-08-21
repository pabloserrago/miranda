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

    /// Catalan is a translation target in its own right, so it must show its own
    /// copy rather than borrowing Spanish or falling back to English.
    @MainActor
    func testCatalanUsesItsOwnCopyNotSpanishOrEnglish() throws {
        let app = launch(language: "ca", locale: "ca_ES")
        openSettings(in: app)

        XCTAssertTrue(
            app.staticTexts["Captura"].waitForExistence(timeout: 3),
            "settings section header is not Catalan; tree:\n\(app.debugDescription)"
        )
        XCTAssertFalse(
            app.staticTexts["Capturar"].exists,
            "Spanish copy leaked into the Catalan build; tree:\n\(app.debugDescription)"
        )
        XCTAssertFalse(
            app.staticTexts["Capture"].exists,
            "English copy leaked into the Catalan build; tree:\n\(app.debugDescription)"
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
