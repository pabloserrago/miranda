import XCTest

/// The editor's controls follow the note's state: a blank page offers only a way
/// out, and the back and confirm controls appear once there is something worth
/// keeping. These tests drive that transition and the word restore history.
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
        XCTAssertFalse(app.buttons["back-note-button"].exists,
                       "back control should be hidden on a blank note")
    }

    @MainActor
    func testTypingRevealsBackAndConfirm() throws {
        let app = launchApp()
        openCreateEditor(in: app)

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText("Buy the plane tickets")

        XCTAssertTrue(app.buttons["save-edit-button"].waitForExistence(timeout: 3),
                      "confirm control did not appear after typing; tree:\n\(app.debugDescription)")
        XCTAssertTrue(app.buttons["back-note-button"].exists,
                      "back control did not appear after typing")
    }

    @MainActor
    func testBackRemovesOneWordAndForwardRestoresIt() throws {
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
        let edited = original + " and then some"
        XCTAssertEqual(editor.value as? String, edited, "typing did not register")

        let back = app.buttons["back-note-button"]
        XCTAssertTrue(back.waitForExistence(timeout: 3))
        back.tap()

        XCTAssertEqual(editor.value as? String, original + " and then ",
                       "back should remove only the previous word; tree:\n\(app.debugDescription)")

        let forward = app.buttons["forward-note-button"]
        XCTAssertTrue(forward.waitForExistence(timeout: 3),
                      "forward should appear after back is used")
        forward.tap()

        XCTAssertEqual(editor.value as? String, edited,
                       "forward did not restore the removed word; tree:\n\(app.debugDescription)")
        XCTAssertFalse(forward.exists, "forward should hide once restore history is exhausted")
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
