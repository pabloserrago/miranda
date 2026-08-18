import Foundation

/// The app's version, read from the bundle rather than written by hand.
///
/// `GENERATE_INFOPLIST_FILE` is on, so these values come straight from
/// `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the build settings.
/// Bumping the version there is enough — nothing else needs editing.
enum AppInfo {

    static let shortVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }()

    static let build: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }()

    /// Version plus build, for the copyable Settings row. The build number is
    /// what distinguishes two uploads sharing a marketing version, so support
    /// requests need it.
    static var displayVersion: String { "\(shortVersion) (\(build))" }
}
