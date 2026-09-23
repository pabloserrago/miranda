import Testing
import UIKit
@testable import ios

struct AppQuickActionTests {
    @Test func mapsEveryRegisteredShortcutType() throws {
        for action in AppQuickAction.allCases {
            let item = UIApplicationShortcutItem(type: action.rawValue, localizedTitle: "Test")
            #expect(AppQuickAction(shortcutItem: item) == action)
        }
    }

    @Test func rejectsUnknownShortcutType() {
        let item = UIApplicationShortcutItem(type: "miranda.unknown", localizedTitle: "Test")
        #expect(AppQuickAction(shortcutItem: item) == nil)
    }
}
