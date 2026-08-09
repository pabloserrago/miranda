import XCTest

final class HyphenSplitEditorUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEnterCommitsHyphenLinesAsSegments() throws {
        let app = launchApp()
        openCreateModal(in: app)

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText("- one note\n")

        let firstSegment = segment(0, in: app)
        XCTAssertTrue(firstSegment.waitForExistence(timeout: 2), "segment not committed; tree:\n\(app.debugDescription)")
        XCTAssertEqual(firstSegment.label, "one note")

        editor.typeText("- another note\n")
        let secondSegment = segment(1, in: app)
        XCTAssertTrue(secondSegment.waitForExistence(timeout: 2))
        XCTAssertEqual(secondSegment.label, "another note")
    }

    @MainActor
    func testPlainLineDoesNotCommitSegment() throws {
        let app = launchApp()
        openCreateModal(in: app)

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText("plain line\n")

        XCTAssertFalse(segment(0, in: app).exists)
    }

    @MainActor
    func testSaveCreatesOneNotePerSegment() throws {
        let app = launchApp()
        openCreateModal(in: app)

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText("- one note\n- another note\n")
        XCTAssertTrue(segment(1, in: app).waitForExistence(timeout: 2))

        app.buttons["Save"].tap()

        // Saved notes render as consolidated row buttons labeled with the note text.
        XCTAssertTrue(
            app.buttons["one note"].waitForExistence(timeout: 3),
            "note not found after save; tree:\n\(app.debugDescription)"
        )
        XCTAssertTrue(app.buttons["another note"].waitForExistence(timeout: 3))
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSeedNotes", "-UITestHyphenSplit"]
        app.launch()
        return app
    }

    @MainActor
    private func openCreateModal(in app: XCUIApplication) {
        let createButton = app.buttons["create-note-button"].firstMatch
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()
    }

    @MainActor
    private func segment(_ index: Int, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: "note-segment-\(index)")
            .firstMatch
    }
}
