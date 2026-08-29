import XCTest

/// The home screen when notes exist but none are priorities: the CTA must open
/// the priority picker (over the already-presented Recent sheet) and the
/// picked note must land on the priority list.
final class NoPriorityEmptyStateUITests: XCTestCase {

    private let waterPlantsNoteId = "22222222-2222-2222-2222-222222222222"

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Launch tests can leave the simulator in landscape, hiding content
        // below the fold (offscreen List cells are never created).
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testEmptyStateOffersTheTurnOnPriorityButton() throws {
        let app = launchAppWithoutPriorities()

        let button = app.buttons["turn-on-priority-button"]
        XCTAssertTrue(
            button.waitForExistence(timeout: 5),
            "turn on priority CTA not found; tree:\n\(app.debugDescription)"
        )

        // No priority rows should render in this state.
        XCTAssertFalse(
            app.descendants(matching: .any)
                .matching(identifier: "priority-note-\(waterPlantsNoteId)")
                .firstMatch.exists
        )
    }

    @MainActor
    func testTurnOnPriorityOpensThePickerOverTheRecentSheet() throws {
        let app = launchAppWithoutPriorities()
        tapTurnOnPriority(in: app)

        // The Recent sheet is already presented at launch here; a second sheet
        // cannot be presented until it closes, so a silent no-op fails here.
        XCTAssertTrue(
            app.navigationBars["Turn on a priority"].waitForExistence(timeout: 5),
            "priority picker did not present; tree:\n\(app.debugDescription)"
        )
    }

    @MainActor
    func testPickingANoteMakesItAPriority() throws {
        let app = launchAppWithoutPriorities()
        tapTurnOnPriority(in: app)
        XCTAssertTrue(app.navigationBars["Turn on a priority"].waitForExistence(timeout: 5))

        let candidate = app.buttons
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Water the plants"))
            .firstMatch
        XCTAssertTrue(
            candidate.waitForExistence(timeout: 3),
            "candidate note not listed in picker; tree:\n\(app.debugDescription)"
        )
        candidate.tap()

        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(
            note.waitForExistence(timeout: 5),
            "picked note did not become a priority; tree:\n\(app.debugDescription)"
        )
    }

    @MainActor
    private func launchAppWithoutPriorities() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSeedNotes", "-UITestNoPriorities"]
        app.launch()
        return app
    }

    @MainActor
    private func tapTurnOnPriority(in app: XCUIApplication) {
        let button = app.buttons["turn-on-priority-button"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }
}
