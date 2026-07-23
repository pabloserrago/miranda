import SwiftUI
import UIKit

enum Haptics {
    static func toggleOn() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func toggleOff() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

extension View {
    func toggleHaptic(_ isOn: Bool) -> some View {
        onChange(of: isOn) { _, newValue in
            newValue ? Haptics.toggleOn() : Haptics.toggleOff()
        }
    }
}
