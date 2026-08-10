import XCTest

/// Verifies the live hyphen-split editor works when *editing an existing note*,
/// mirroring the create-modal behaviour. Uses `-UITestHyphenSplitEdit`, which
/// enables Split by Hyphens without force-opening the recent sheet, so a seeded
/// priority note is directly tappable.
final class HyphenSplitEditEditorUITests: XCTestCase {

    private let medicineNoteId = "11111111-1111-1111-1111-111111111111"

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Launch tests cycle device orientations and can leave the simulator
        // in landscape, where the third seeded card is offscreen and its List
        // cell is never created.
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testEditEnterCommitsHyphenLineAsSegment() throws {
        let app = launchApp()
        openEditor(in: app)

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        // Append a hyphen line and commit it with Enter.
        editor.typeText("\n- extra note\n")

        let firstSegment = segment(0, in: app)
        XCTAssertTrue(
            firstSegment.waitForExistence(timeout: 2),
            "segment not committed in edit mode; tree:\n\(app.debugDescription)"
        )
        // The leading original text becomes its own segment, the hyphen line the next.
        XCTAssertTrue(segment(1, in: app).waitForExistence(timeout: 2))
        XCTAssertEqual(segment(1, in: app).label, "extra note")
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSeedNotes", "-UITestHyphenSplitEdit"]
        app.launch()
        return app
    }

    @MainActor
    private func openEditor(in app: XCUIApplication) {
        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(medicineNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()

        let editButton = app.buttons["edit-note-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()
    }

    @MainActor
    private func segment(_ index: Int, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: "note-segment-\(index)")
            .firstMatch
    }
}
