import XCTest

/// Regression tests for the long-press "lift" that starts a priority reorder.
///
/// The lift must fire while the finger is completely stationary. A plain
/// `.onLongPressGesture` on a Button only wins the gesture arbitration once
/// movement cancels the button's own press, so a stationary hold either falls
/// through to the tap action (opening the editor) or does nothing.
final class PriorityReorderLiftUITests: XCTestCase {

    private let waterPlantsNoteId = "22222222-2222-2222-2222-222222222222"

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Launch tests can leave the simulator in landscape, hiding seeded
        // cards below the fold (offscreen List cells are never created).
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testStationaryLongPressLiftsInsteadOfOpeningEditor() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSeedNotes"]
        app.launch()

        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))

        // Press and hold without any movement, then release. A working lift
        // consumes this touch; the buggy build lets the Button's tap fire.
        note.press(forDuration: 0.8)

        XCTAssertFalse(
            app.buttons["close-note-button"].waitForExistence(timeout: 1.5),
            "Detail editor opened — the stationary long press fell through to the tap instead of lifting the card"
        )

        // The lift-then-release with no drag must fully reset reorder state:
        // a normal tap afterwards still opens the editor.
        note.tap()
        XCTAssertTrue(
            app.buttons["close-note-button"].waitForExistence(timeout: 3),
            "Tap after a stationary lift-and-release did not open the editor — reorder state is stuck"
        )
    }
}
