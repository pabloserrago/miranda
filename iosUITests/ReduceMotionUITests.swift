import XCTest

/// Reduce Motion must suppress the completion celebration, which is the app's
/// one full-screen animated flourish and the only motion with an observable
/// on-screen consequence.
///
/// The `-UITestReduceMotion` launch argument overrides the
/// `\.accessibilityReduceMotion` environment value at the app root, because the
/// simulator's Reduce Motion setting cannot be toggled from XCUITest.
final class ReduceMotionUITests: XCTestCase {

    private let waterPlantsNoteId = "22222222-2222-2222-2222-222222222222"

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testCelebrationPlaysWhenReduceMotionIsOff() throws {
        let app = launch(reduceMotion: false)
        completeSeededNote(in: app)

        XCTAssertTrue(
            celebration(in: app).waitForExistence(timeout: 3),
            "completion celebration did not appear with Reduce Motion off; tree:\n\(app.debugDescription)"
        )
    }

    @MainActor
    func testCelebrationIsSuppressedWhenReduceMotionIsOn() throws {
        let app = launch(reduceMotion: true)
        completeSeededNote(in: app)

        XCTAssertFalse(
            celebration(in: app).waitForExistence(timeout: 3),
            "completion celebration played despite Reduce Motion; tree:\n\(app.debugDescription)"
        )
    }

    @MainActor
    private func celebration(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: "completion-celebration")
            .firstMatch
    }

    @MainActor
    private func completeSeededNote(in app: XCUIApplication) {
        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.swipeLeft()
        let complete = app.buttons["Complete"]
        XCTAssertTrue(complete.waitForExistence(timeout: 2))
        complete.tap()
    }

    @MainActor
    private func launch(reduceMotion: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSeedNotes"]
        if reduceMotion {
            app.launchArguments.append("-UITestReduceMotion")
        }
        app.launch()
        return app
    }
}
