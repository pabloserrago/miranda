import Foundation
import Testing
@testable import ios

/// Notification copy is handed to `UNMutableNotificationContent` as a plain
/// `String`, which Xcode never extracts for localization. These tests pin the
/// titles to catalog lookups so a hardcoded literal cannot creep back in.
struct NotificationTitleTests {

    static let titleKeys = [
        "notification.priority_update.title",
        "notification.daily_digest.title",
    ]

    @Test func titlesResolveFromTheCatalog() {
        // A failed lookup returns the key itself, which is how a typo'd or
        // missing catalog entry shows up at runtime.
        #expect(NotificationManager.priorityUpdateTitle != Self.titleKeys[0])
        #expect(NotificationManager.dailyDigestTitle != Self.titleKeys[1])
    }

    @Test func titlesAreNotEmpty() {
        #expect(!NotificationManager.priorityUpdateTitle.isEmpty)
        #expect(!NotificationManager.dailyDigestTitle.isEmpty)
    }

    /// Asserted against `en.lproj` rather than the running locale so the test
    /// holds regardless of how the simulator is configured.
    @Test func englishSourceCopyIsUnchanged() throws {
        let url = try #require(Bundle.main.url(forResource: "en", withExtension: "lproj"))
        let english = try #require(Bundle(url: url))

        #expect(english.localizedString(forKey: Self.titleKeys[0], value: nil, table: nil)
                == "Your priorities")
        #expect(english.localizedString(forKey: Self.titleKeys[1], value: nil, table: nil)
                == "Good morning — your priorities")
    }
}
