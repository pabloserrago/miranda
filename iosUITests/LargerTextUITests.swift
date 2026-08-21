import XCTest

/// Exercises the main flows at the largest Larger Accessibility Text size.
///
/// Apple's Larger Text nutrition label requires the app to stay usable at the
/// biggest setting, so every assertion here checks that a control is not just
/// present but still hittable — an element pushed off-screen by grown type
/// exists in the tree yet cannot be tapped.
final class LargerTextUITests: XCTestCase {

    private let waterPlantsNoteId = "22222222-2222-2222-2222-222222222222"

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testPriorityListIsUsableAtLargestAccessibilitySize() throws {
        let app = launchAtAX5()

        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5),
                      "seeded priority note missing at AX5; tree:\n\(app.debugDescription)")
        XCTAssertTrue(note.isHittable, "priority note is not hittable at AX5")
    }

    @MainActor
    func testCreateButtonStaysHittableAtLargestAccessibilitySize() throws {
        let app = launchAtAX5()
        let create = openRecentSheetAndFindCreateButton(in: app)
        XCTAssertTrue(create.isHittable, "create button is not hittable at AX5")
    }

    @MainActor
    func testNoteDetailIsReadableAtLargestAccessibilitySize() throws {
        let app = launchAtAX5()

        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()

        let edit = app.descendants(matching: .any)
            .matching(identifier: "edit-note-button")
            .firstMatch
        XCTAssertTrue(edit.waitForExistence(timeout: 3),
                      "note detail did not open at AX5; tree:\n\(app.debugDescription)")
        XCTAssertTrue(edit.isHittable, "Edit is not hittable at AX5")
        XCTAssertTrue(app.buttons["close-note-button"].isHittable, "Close is not hittable at AX5")

        // The two bottom actions sit side by side at default sizes and stack at
        // accessibility sizes, where two capsules no longer fit on one row.
        let toggle = app.buttons["toggle-priority-button"]
        let done = app.buttons["done-button"]
        XCTAssertTrue(toggle.isHittable, "the priority toggle is not hittable at AX5")
        XCTAssertTrue(done.isHittable, "Done is not hittable at AX5")
        XCTAssertNotEqual(toggle.frame.midY, done.frame.midY,
                          "the bottom actions should stack rather than share a row at AX5")
    }

    @MainActor
    func testCreateModalIsUsableAtLargestAccessibilitySize() throws {
        let app = launchAtAX5()
        openRecentSheetAndFindCreateButton(in: app).tap()

        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 3),
                      "create modal did not open at AX5; tree:\n\(app.debugDescription)")
        XCTAssertTrue(app.buttons["Cancel"].isHittable, "Cancel is not hittable at AX5")
    }

    /// The recent sheet holds the create button and is not auto-presented under
    /// a UI-test launch, so open it the way a sighted user does — a downward
    /// drag on the card list.
    @MainActor
    @discardableResult
    private func openRecentSheetAndFindCreateButton(in app: XCUIApplication) -> XCUIElement {
        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))

        let create = app.descendants(matching: .any)
            .matching(identifier: "create-note-button")
            .firstMatch

        app.swipeDown()
        XCTAssertTrue(create.waitForExistence(timeout: 3),
                      "recent sheet did not open at AX5; tree:\n\(app.debugDescription)")
        return create
    }

    @MainActor
    private func launchAtAX5() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITestSeedNotes",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL",
        ]
        app.launch()
        return app
    }
}
