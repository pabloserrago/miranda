import XCTest

final class PriorityNoteSwipeUITests: XCTestCase {

    private let waterPlantsNoteId = "22222222-2222-2222-2222-222222222222"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSeededNotesAppear() throws {
        let app = launchSeededApp()
        // In a List the row becomes a cell — search broadly
        let note = app.descendants(matching: .any).matching(identifier: "priority-note-\(waterPlantsNoteId)").firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5), "priority note not found; tree:\n\(app.debugDescription)")
    }

    @MainActor
    func testSwipeRightRevealsRemoveActionOnLeft() throws {
        let app = launchSeededApp()
        let note = priorityNote(in: app)
        note.swipeRight()
        XCTAssertTrue(app.buttons["Remove"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSwipeLeftRevealsCompleteAndDeleteActionsOnRight() throws {
        let app = launchSeededApp()
        let note = priorityNote(in: app)
        note.swipeLeft()
        XCTAssertTrue(app.buttons["Complete"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSwipeRightRemoveExcludesNoteFromPriorityList() throws {
        let app = launchSeededApp()
        let note = priorityNote(in: app)
        note.swipeRight()
        app.buttons["Remove"].tap()

        XCTAssertTrue(waitForElementToDisappear(note, timeout: 3))
        XCTAssertTrue(
            app.descendants(matching: .any)
               .matching(identifier: "priority-note-33333333-3333-3333-3333-333333333333")
               .firstMatch.exists
        )
    }

    @MainActor
    func testSwipeLeftDeleteRemovesNote() throws {
        let app = launchSeededApp()
        let note = priorityNote(in: app)
        note.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(waitForElementToDisappear(note, timeout: 3))
    }

    @MainActor
    private func launchSeededApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSeedNotes"]
        app.launch()
        return app
    }

    @MainActor
    private func priorityNote(in app: XCUIApplication) -> XCUIElement {
        let note = app.descendants(matching: .any)
            .matching(identifier: "priority-note-\(waterPlantsNoteId)")
            .firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 3))
        return note
    }

    @MainActor
    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
