import XCTest

/// The editor's controls follow the note's state: a blank page offers only a way
/// out, and the undo and confirm controls appear once there is something worth
/// keeping. These tests drive that transition and the undo stack behind it.
final class NoteEditorChromeUITests: XCTestCase {

    private let waterPlantsNoteId = "22222222-2222-2222-2222-222222222222"

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Launch tests cycle orientations and can leave the simulator in
        // landscape, where seeded cards fall below the fold and their List
        // cells are never created.
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testEmptyEditorOffersOnlyCancel() throws {
        let app = launchApp()
        openCreateEditor(in: app)

        XCTAssertTrue(app.buttons["cancel-edit-button"].waitForExistence(timeout: 3),
                      "editor did not open; tree:\n\(app.debugDescription)")
        XCTAssertFalse(app.buttons["save-edit-button"].exists,
                       "confirm control should be hidden on a blank note")
        XCTAssertFalse(app.buttons["undo-note-button"].exists,
                       "undo control should be hidden on a blank note")
    }

    @MainActor
    func testTypingRevealsUndoAndConfirm() throws {
        let app = launchApp()
        openCreateEditor(in: app)

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText("Buy the plane tickets")

        XCTAssertTrue(app.buttons["save-edit-button"].waitForExistence(timeout: 3),
                      "confirm control did not appear after typing; tree:\n\(app.debugDescription)")
        XCTAssertTrue(app.buttons["undo-note-button"].exists,
                      "undo control did not appear after typing")
    }

    @MainActor
    func testUndoRevertsTypingInEditMode() throws {
        let app = launchApp()

        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()

        app.buttons["note-actions-menu-button"].tap()
        let edit = app.buttons["edit-note-button"]
        XCTAssertTrue(edit.waitForExistence(timeout: 3))
        edit.tap()

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        let original = editor.value as? String ?? ""
        XCTAssertFalse(original.isEmpty, "edit mode should open with the note's text")

        editor.tap()
        editor.typeText(" and then some")
        XCTAssertNotEqual(editor.value as? String, original, "typing did not register")

        let undo = app.buttons["undo-note-button"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        undo.tap()

        XCTAssertEqual(editor.value as? String, original,
                       "undo did not restore the text; tree:\n\(app.debugDescription)")
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSeedNotes"]
        app.launch()
        return app
    }

    /// The create control lives in the recent sheet, which a UI-test launch does
    /// not auto-present, so open it the way a sighted user does.
    @MainActor
    private func openCreateEditor(in app: XCUIApplication) {
        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))

        let create = app.buttons["create-note-button"].firstMatch
        app.swipeDown()
        XCTAssertTrue(create.waitForExistence(timeout: 3),
                      "recent sheet did not open; tree:\n\(app.debugDescription)")
        create.tap()
    }
}
