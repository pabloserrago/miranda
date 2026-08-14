import XCTest

/// First-launch onboarding flow: capture a note (step 1), widget upsell
/// showing that note (step 2), personalization (step 3). Forward-only, no skip.
/// The `-UITestShowOnboarding` launch argument clears the completion flag so
/// the flow shows deterministically regardless of the simulator's container.
final class OnboardingUITests: XCTestCase {

    private let noteText = "Buy the plane tickets"

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Launch tests can leave the simulator in landscape, hiding content
        // below the fold (offscreen List cells are never created).
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testCompletionFlowCarriesNoteAndNeverShowsAgain() throws {
        let app = launchOnboardingApp()

        // Step 1
        let addNoteButton = app.buttons["onboarding-add-first-note"]
        XCTAssertTrue(addNoteButton.waitForExistence(timeout: 5), "step 1 not shown; tree:\n\(app.debugDescription)")
        addNoteButton.tap()

        // New Note sheet: type and save
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText(noteText)
        app.buttons["Save"].tap()

        // Step 2: shows the saved note inside the widget preview
        let continueButton = app.buttons["onboarding-continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 3), "step 2 not shown; tree:\n\(app.debugDescription)")
        XCTAssertTrue(
            app.staticTexts[noteText].firstMatch.exists,
            "saved note not visible on step 2; tree:\n\(app.debugDescription)"
        )
        XCTAssertTrue(app.buttons["onboarding-add-widget"].exists)
        continueButton.tap()

        // Step 3: personalization, then finish
        let finishButton = app.buttons["onboarding-finish"]
        XCTAssertTrue(finishButton.waitForExistence(timeout: 3), "step 3 not shown; tree:\n\(app.debugDescription)")
        finishButton.tap()

        // Onboarding dismissed; the note is in the main app as priority.
        // The priority card is a Button whose label is the note text (the
        // card flattens its accessibility children), so match by label.
        XCTAssertTrue(waitForElementToDisappear(finishButton, timeout: 3))
        let noteInList = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", noteText))
            .firstMatch
        XCTAssertTrue(
            noteInList.waitForExistence(timeout: 3),
            "note not visible in main app after finishing; tree:\n\(app.debugDescription)"
        )

        // Relaunch without the reset argument: the persisted flag must keep
        // onboarding hidden.
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertFalse(
            app.buttons["onboarding-add-first-note"].waitForExistence(timeout: 3),
            "onboarding shown again after completion"
        )
    }

    @MainActor
    func testStepTwoOpensWidgetInstructions() throws {
        let app = launchOnboardingApp()
        advanceToStepTwo(in: app)

        app.buttons["onboarding-add-widget"].tap()
        XCTAssertTrue(
            app.staticTexts["Widget on Home Screen"].waitForExistence(timeout: 3),
            "widget instructions not shown; tree:\n\(app.debugDescription)"
        )
    }

    @MainActor
    func testCancellingNoteSheetStaysOnStepOne() throws {
        let app = launchOnboardingApp()

        let addNoteButton = app.buttons["onboarding-add-first-note"]
        XCTAssertTrue(addNoteButton.waitForExistence(timeout: 5))
        addNoteButton.tap()

        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3))
        cancelButton.tap()

        XCTAssertTrue(
            addNoteButton.waitForExistence(timeout: 3),
            "step 1 not visible after cancelling the note sheet"
        )
        XCTAssertFalse(app.buttons["onboarding-continue"].exists, "flow advanced without a saved note")
    }

    // MARK: - Helpers

    @MainActor
    private func launchOnboardingApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestShowOnboarding"]
        app.launch()
        return app
    }

    @MainActor
    private func advanceToStepTwo(in app: XCUIApplication) {
        let addNoteButton = app.buttons["onboarding-add-first-note"]
        XCTAssertTrue(addNoteButton.waitForExistence(timeout: 5))
        addNoteButton.tap()

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText(noteText)
        app.buttons["Save"].tap()

        XCTAssertTrue(app.buttons["onboarding-continue"].waitForExistence(timeout: 3))
    }

    @MainActor
    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
