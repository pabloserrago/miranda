import XCTest

/// Voice Control drives the app by speaking a control's name, so every
/// icon-only button needs an accessibility label. These tests query purely by
/// label — the way Voice Control resolves "Tap <name>" — so a missing or
/// renamed label fails here rather than silently stranding the user.
final class VoiceControlNamingUITests: XCTestCase {

    private let waterPlantsNoteId = "22222222-2222-2222-2222-222222222222"

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testSettingsButtonIsAddressableByName() throws {
        let app = launchSeededApp()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5),
                      "no control named Settings; tree:\n\(app.debugDescription)")
    }

    @MainActor
    func testRecentSheetControlsAreAddressableByName() throws {
        let app = launchSeededApp()
        openRecentSheet(in: app)

        XCTAssertTrue(app.buttons["New note"].waitForExistence(timeout: 3),
                      "no control named New note; tree:\n\(app.debugDescription)")
    }

    @MainActor
    func testEditControlsAreAddressableByName() throws {
        let app = launchSeededApp()

        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()

        app.buttons["Edit"].tap()

        XCTAssertTrue(app.buttons["Save note"].waitForExistence(timeout: 3),
                      "no control named Save note; tree:\n\(app.debugDescription)")
        XCTAssertTrue(app.buttons["Cancel edit"].exists,
                      "no control named Cancel edit; tree:\n\(app.debugDescription)")
    }

    @MainActor
    private func openRecentSheet(in app: XCUIApplication) {
        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        app.swipeDown()
    }

    @MainActor
    private func launchSeededApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSeedNotes"]
        app.launch()
        return app
    }
}
