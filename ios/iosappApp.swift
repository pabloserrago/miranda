import SwiftUI

@main
struct iosappApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var quickActionRouter = AppQuickActionRouter.shared

    init() {
        SharedCardManager.migrateBackgroundTheme(from: .standard)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(quickActionRouter)
        }
    }
}
