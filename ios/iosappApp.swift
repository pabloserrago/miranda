import SwiftUI

@main
struct iosappApp: App {
    init() {
        SharedCardManager.migrateBackgroundTheme(from: .standard)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
