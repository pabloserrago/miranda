import Foundation
import Testing
@testable import ios

struct AppStoreLinkTests {

    @Test("Write-review link uses the numeric app ID and the review action")
    func writeReviewURLUsesNumericIDWithReviewAction() {
        #expect(AppStoreLink.writeReviewURL.absoluteString
                == "https://apps.apple.com/app/id6759875091?action=write-review")
    }

    /// A storefront segment (`/es/`) would send everyone to the Spanish store.
    @Test("Write-review link carries no storefront segment")
    func writeReviewURLHasNoStorefront() {
        #expect(AppStoreLink.writeReviewURL.path == "/app/id\(AppStoreLink.id)")
    }
}
