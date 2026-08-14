import XCTest

/// Covers the pointer-free route into the recent sheet.
///
/// The row's Move Up / Move Down actions are not asserted here: XCUITest does
/// not surface SwiftUI `accessibilityActions` in the element tree, so there is
/// nothing to query. The orderings they commit are covered by
/// `ReorderAccessibilityActionTests` instead.
final class ReorderAccessibilityActionUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testRecentSheetIsReachableWithoutDragging() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestSeedNotes"]
        app.launch()

        let show = app.buttons["Show recent notes"]
        XCTAssertTrue(show.waitForExistence(timeout: 5),
                      "no pointer-free way to open the recent sheet; tree:\n\(app.debugDescription)")
        show.tap()

        XCTAssertTrue(app.buttons["New note"].waitForExistence(timeout: 3),
                      "recent sheet did not open from the toolbar control; tree:\n\(app.debugDescription)")
    }
}
