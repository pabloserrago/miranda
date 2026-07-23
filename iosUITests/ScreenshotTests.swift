import XCTest

/// Takes the two automated App Store screenshots:
///   01-priority-list.png   – main screen with seeded priority cards
///   02-capture-modal.png   – New Note bottom sheet
///
/// Seed data is written by take-screenshots.sh (scripts/seed_defaults.py)
/// before this test suite runs. Both tests rely on that pre-seeded state.
final class ScreenshotTests: XCTestCase {

    private let outDir = "/Users/pserrano/adhd/screenshots/app-store"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Screenshots

    @MainActor
    func testPriorityList() throws {
        let app = XCUIApplication()
        app.launch()
        // Wait for cards and recent sheet to render
        sleep(4)
        save(XCUIScreen.main.screenshot(), name: "01-priority-list.png")
        app.terminate()
    }

    @MainActor
    func testCaptureModal() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(3)

        // Tap the "+" button in the recent sheet's navigation bar.
        // iOS auto-labels Image(systemName: "plus") as "Add".
        let plusButton = app.buttons.matching(NSPredicate(format:
            "label == 'Add' OR label == 'New Note' OR label == 'plus'")).firstMatch

        if plusButton.waitForExistence(timeout: 4) {
            plusButton.tap()
        }
        sleep(2)
        save(XCUIScreen.main.screenshot(), name: "02-capture-modal.png")
        app.terminate()
    }

    // MARK: - Helpers

    private func save(_ screenshot: XCUIScreenshot, name: String) {
        try? FileManager.default.createDirectory(
            atPath: outDir, withIntermediateDirectories: true)
        let url = URL(fileURLWithPath: "\(outDir)/\(name)")
        if (try? screenshot.pngRepresentation.write(to: url)) != nil {
            print("Screenshot saved: \(url.path)")
        }
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
