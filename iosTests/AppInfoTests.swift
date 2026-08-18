import Foundation
import Testing
@testable import ios

/// Guards that the version shown in Settings is read from the bundle.
///
/// Settings previously displayed a hardcoded "1.0.0" that nobody remembered to
/// update, so the number users copied into support requests was three releases
/// stale. Reading from the bundle means `MARKETING_VERSION` and
/// `CURRENT_PROJECT_VERSION` are the only places a version is ever written.
struct AppInfoTests {

    @Test
    func shortVersionComesFromBundle() {
        let expected = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        #expect(AppInfo.shortVersion == expected)
        #expect(!AppInfo.shortVersion.isEmpty)
    }

    @Test
    func buildComesFromBundle() {
        let expected = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        #expect(AppInfo.build == expected)
        #expect(!AppInfo.build.isEmpty)
    }

    @Test
    func displayVersionCombinesVersionAndBuild() {
        #expect(AppInfo.displayVersion == "\(AppInfo.shortVersion) (\(AppInfo.build))")
    }
}
