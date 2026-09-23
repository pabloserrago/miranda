import Combine
import UIKit

enum AppQuickAction: String, CaseIterable {
    case newNote = "miranda.new-note"
    case newVoiceNote = "miranda.new-voice-note"
    case searchNotes = "miranda.search-notes"
    case setPriority = "miranda.set-priority"

    init?(shortcutItem: UIApplicationShortcutItem) {
        self.init(rawValue: shortcutItem.type)
    }
}

@MainActor
final class AppQuickActionRouter: ObservableObject {
    static let shared = AppQuickActionRouter()

    @Published private(set) var pendingAction: AppQuickAction?

    private init() {}

    func handle(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let action = AppQuickAction(shortcutItem: shortcutItem) else { return false }
        pendingAction = action
        return true
    }

    func consumePendingAction() -> AppQuickAction? {
        defer { pendingAction = nil }
        return pendingAction
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
        if connectingSceneSession.role == .windowApplication {
            configuration.delegateClass = AppSceneDelegate.self
        }
        return configuration
    }
}

@MainActor
final class AppSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let shortcutItem = connectionOptions.shortcutItem else { return }
        _ = AppQuickActionRouter.shared.handle(shortcutItem)
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem
    ) async -> Bool {
        AppQuickActionRouter.shared.handle(shortcutItem)
    }
}
