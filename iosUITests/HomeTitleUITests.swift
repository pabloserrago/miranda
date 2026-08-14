import XCTest

/// The home screen shows the app title in the navigation bar without
/// displacing the turtle settings button that shares the same bar.
final class HomeTitleUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Launch tests can leave the simulator in landscape, hiding content
        // below the fold (offscreen List cells are never created).
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testHomeShowsAppTitle() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSeedNotes"]
        app.launch()

        let title = app.staticTexts["home-title"]
        XCTAssertTrue(
            title.waitForExistence(timeout: 5),
            "app title not visible on the home screen; tree:\n\(app.debugDescription)"
        )
        XCTAssertEqual(title.label, "Miranda First")

        // The principal title must not swallow the leading settings button.
        // Queried by identifier: its accessibility label overrides the emoji.
        let settingsButton = app.buttons["settings-button"]
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: 3),
            "settings button missing from the toolbar; tree:\n\(app.debugDescription)"
        )
        settingsButton.tap()
        XCTAssertTrue(
            app.staticTexts["Capture"].waitForExistence(timeout: 3),
            "settings sheet did not open; tree:\n\(app.debugDescription)"
        )
    }
}
