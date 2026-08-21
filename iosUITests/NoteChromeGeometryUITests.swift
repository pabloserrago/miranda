import XCTest

/// The editor and the preview are the same sheet as far as the user is
/// concerned, so the control row across the top must not move when one replaces
/// the other, and its inset from the left edge must equal its inset from the
/// right.
///
/// This is measured rather than eyeballed: the row drifted twice — once because
/// the editor inset its row while the preview stacked it, and once because the
/// two screens carried their own copies of the padding constants.
final class NoteChromeGeometryUITests: XCTestCase {

    private let waterPlantsNoteId = "22222222-2222-2222-2222-222222222222"

    /// Frames come back in points and can carry sub-pixel rounding.
    private let tolerance: CGFloat = 1.0

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testPreviewAndEditorRowsShareTheSameGeometry() throws {
        let app = launchSeededApp()
        openSeededNote(in: app)

        let preview = try measureRow(
            in: app, leading: "close-note-button", trailing: "edit-note-button"
        )

        app.buttons["edit-note-button"].tap()

        let editor = try measureRow(
            in: app, leading: "cancel-edit-button", trailing: "save-edit-button"
        )

        print("preview row: \(preview)")
        print("editor row:  \(editor)")

        XCTAssertEqual(preview.top, editor.top, accuracy: tolerance,
                       "the rows sit at different distances from the top of the sheet")
        XCTAssertEqual(preview.leadingInset, editor.leadingInset, accuracy: tolerance,
                       "the rows start at different distances from the left edge")
        XCTAssertEqual(preview.trailingInset, editor.trailingInset, accuracy: tolerance,
                       "the rows end at different distances from the right edge")
    }

    @MainActor
    func testPreviewRowInsetsAreSymmetric() throws {
        let app = launchSeededApp()
        openSeededNote(in: app)

        let row = try measureRow(
            in: app, leading: "close-note-button", trailing: "edit-note-button"
        )
        XCTAssertEqual(row.leadingInset, row.trailingInset, accuracy: tolerance,
                       "the preview's row is not centred between the sheet edges: \(row)")
    }

    @MainActor
    func testEditorRowInsetsAreSymmetric() throws {
        let app = launchSeededApp()
        openCreateEditor(in: app)

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        // The undo and confirm controls only exist once the note has content.
        editor.typeText("Buy the plane ticket")

        let row = try measureRow(
            in: app, leading: "cancel-edit-button", trailing: "save-edit-button"
        )
        XCTAssertEqual(row.leadingInset, row.trailingInset, accuracy: tolerance,
                       "the editor's row is not centred between the sheet edges: \(row)")
    }

    /// The flow the user actually sees: write a note, save it, and the preview
    /// takes over the same sheet.
    @MainActor
    func testRowDoesNotMoveWhenSavingSwapsEditorForPreview() throws {
        let app = launchSeededApp()
        openCreateEditor(in: app)

        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        textView.tap()
        textView.typeText("Buy the plane ticket")

        let editor = try measureRow(
            in: app, leading: "cancel-edit-button", trailing: "save-edit-button"
        )

        app.buttons["save-edit-button"].tap()
        XCTAssertTrue(app.buttons["close-note-button"].waitForExistence(timeout: 5))

        let preview = try measureRow(
            in: app, leading: "close-note-button", trailing: "edit-note-button"
        )

        print("editor row:  \(editor)")
        print("preview row: \(preview)")

        XCTAssertEqual(editor.top, preview.top, accuracy: tolerance,
                       "the row jumped vertically when the preview replaced the editor")
        XCTAssertEqual(editor.leadingInset, preview.leadingInset, accuracy: tolerance,
                       "the row's leading inset changed when the preview replaced the editor")
        XCTAssertEqual(editor.trailingInset, preview.trailingInset, accuracy: tolerance,
                       "the row's trailing inset changed when the preview replaced the editor")
    }

    // MARK: - Measurement

    private struct RowGeometry: CustomStringConvertible {
        let top: CGFloat
        let leadingInset: CGFloat
        let trailingInset: CGFloat
        let height: CGFloat

        var description: String {
            "top=\(top) leading=\(leadingInset) trailing=\(trailingInset) height=\(height)"
        }
    }

    /// A SwiftUI sheet is not exposed as an `sheets` element, so `top` ends up
    /// measured from the window and includes the sheet's own offset. That is
    /// still sound for comparing two screens presented the same way, which is
    /// what these tests do — the absolute top inset is fixed instead by
    /// `NoteChromeRow` applying one constant to all three of its outer edges.
    @MainActor
    private func measureRow(
        in app: XCUIApplication, leading: String, trailing: String
    ) throws -> RowGeometry {
        let leadingButton = app.buttons[leading]
        let trailingButton = app.buttons[trailing]
        XCTAssertTrue(leadingButton.waitForExistence(timeout: 5),
                      "\(leading) missing; tree:\n\(app.debugDescription)")
        XCTAssertTrue(trailingButton.waitForExistence(timeout: 5),
                      "\(trailing) missing; tree:\n\(app.debugDescription)")

        let sheet = sheetFrame(in: app)
        return RowGeometry(
            top: leadingButton.frame.minY - sheet.minY,
            leadingInset: leadingButton.frame.minX - sheet.minX,
            trailingInset: sheet.maxX - trailingButton.frame.maxX,
            height: leadingButton.frame.height
        )
    }

    /// The sheet's own bounds when one is presented, falling back to the window.
    @MainActor
    private func sheetFrame(in app: XCUIApplication) -> CGRect {
        let sheet = app.sheets.firstMatch
        if sheet.exists, sheet.frame.height > 0 { return sheet.frame }
        return app.windows.firstMatch.frame
    }

    // MARK: - Helpers

    @MainActor
    private func openSeededNote(in app: XCUIApplication) {
        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
    }

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
