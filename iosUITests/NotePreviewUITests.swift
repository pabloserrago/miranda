import XCTest

/// Saving a note now shows it back rather than dropping straight to home, and
/// the same screen is what a tapped note opens. These tests drive that flow and
/// the three controls the design puts around it: close, new note, edit.
final class NotePreviewUITests: XCTestCase {

    private let waterPlantsNoteId = "22222222-2222-2222-2222-222222222222"

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testSavingANoteShowsItsPreview() throws {
        let app = launchSeededApp()
        openCreateEditor(in: app)

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText("Buy the plane ticket")

        app.buttons["save-edit-button"].tap()

        XCTAssertTrue(app.buttons["close-note-button"].waitForExistence(timeout: 3),
                      "saving did not open the preview; tree:\n\(app.debugDescription)")
        XCTAssertTrue(app.staticTexts["Buy the plane ticket"].exists,
                      "the preview did not show the saved note; tree:\n\(app.debugDescription)")
        XCTAssertFalse(app.buttons["save-edit-button"].exists,
                       "the editor is still showing behind the preview")
    }

    @MainActor
    func testPreviewOffersCloseNewNoteAndEdit() throws {
        let app = launchSeededApp()
        openSeededNote(in: app)

        XCTAssertTrue(app.buttons["close-note-button"].waitForExistence(timeout: 3),
                      "no close control; tree:\n\(app.debugDescription)")
        XCTAssertTrue(app.buttons["new-note-from-preview-button"].exists,
                      "no new-note control; tree:\n\(app.debugDescription)")
        XCTAssertTrue(app.buttons["edit-note-button"].exists,
                      "no edit control; tree:\n\(app.debugDescription)")
    }

    @MainActor
    func testPreviewShowsBothActionsSideBySide() throws {
        let app = launchSeededApp()
        openSeededNote(in: app)

        let toggle = app.buttons["toggle-priority-button"]
        let done = app.buttons["done-button"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3),
                      "no priority toggle; tree:\n\(app.debugDescription)")
        XCTAssertTrue(done.exists, "no done action; tree:\n\(app.debugDescription)")

        // Side by side, not stacked: same row, done to the right of the toggle.
        XCTAssertEqual(toggle.frame.midY, done.frame.midY, accuracy: 2,
                       "the two actions are not on the same row")
        XCTAssertLessThan(toggle.frame.maxX, done.frame.minX + 1,
                          "the done action should sit to the right of the toggle")

        // Neither label may wrap, which is what retired the longer "Mark as
        // Done". A capsule is 28pt of padding around a ~20pt line, so a single
        // line lands near 48–52pt and a wrapped one near 69pt. The two differ by
        // 4pt because the lightbulb glyph is taller than the checkmark.
        let singleLineCeiling: CGFloat = 60
        XCTAssertLessThan(done.frame.height, singleLineCeiling,
                          "the Done label wrapped onto a second line")
        XCTAssertLessThan(toggle.frame.height, singleLineCeiling,
                          "the priority toggle's label wrapped onto a second line")
    }

    @MainActor
    func testPencilOpensTheEditorOnTheNote() throws {
        let app = launchSeededApp()
        openSeededNote(in: app)

        app.buttons["edit-note-button"].tap()

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3),
                      "the pencil did not open the editor; tree:\n\(app.debugDescription)")
        let text = editor.value as? String ?? ""
        XCTAssertTrue(text.contains("Water the plants"),
                      "the editor did not open on the note's text, got: \(text)")
    }

    @MainActor
    func testPlusOpensABlankEditor() throws {
        let app = launchSeededApp()
        openSeededNote(in: app)

        app.buttons["new-note-from-preview-button"].tap()

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3),
                      "the plus did not open the editor; tree:\n\(app.debugDescription)")
        let text = editor.value as? String ?? ""
        XCTAssertFalse(text.contains("Water the plants"),
                       "the plus should open a blank note, got: \(text)")
        XCTAssertFalse(app.buttons["save-edit-button"].exists,
                       "a blank note should not offer the confirm control")
    }

    @MainActor
    func testPlusFromASavedPreviewReturnsToABlankEditor() throws {
        let app = launchSeededApp()
        openCreateEditor(in: app)

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText("Buy the plane ticket")
        app.buttons["save-edit-button"].tap()

        XCTAssertTrue(app.buttons["new-note-from-preview-button"].waitForExistence(timeout: 3))
        app.buttons["new-note-from-preview-button"].tap()

        XCTAssertTrue(app.buttons["cancel-edit-button"].waitForExistence(timeout: 3),
                      "the plus did not return to the editor; tree:\n\(app.debugDescription)")
        XCTAssertFalse(app.staticTexts["Buy the plane ticket"].exists,
                       "the new note opened on the previous note's text")
    }

    // The control row's placement across both screens is measured in
    // `NoteChromeGeometryUITests`.

    // MARK: - Helpers

    @MainActor
    private func openSeededNote(in app: XCUIApplication) {
        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
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

    @MainActor
    private func launchSeededApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSeedNotes"]
        app.launch()
        return app
    }
}
