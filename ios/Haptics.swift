import SwiftUI
import UIKit

enum Haptics {
    static func toggleOn() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func toggleOff() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    // MARK: Reorder
    // Shared generators kept alive so the Taptic Engine stays warm; a generator
    // created inline and fired immediately can drop or delay its first haptic.

    private static let reorderLiftGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let reorderTickGenerator = UISelectionFeedbackGenerator()

    /// Warm up the engine while the user is still holding the card, so the
    /// lift impact plays the instant the long press fires.
    static func prepareReorderLift() {
        reorderLiftGenerator.prepare()
    }

    /// Impact confirming the card has lifted and can be dragged.
    static func reorderLift() {
        reorderLiftGenerator.impactOccurred()
        reorderTickGenerator.prepare()
    }

    /// Light tick fired when a dragged priority card crosses into a new slot.
    static func reorderTick() {
        reorderTickGenerator.selectionChanged()
        reorderTickGenerator.prepare()
    }
}

extension View {
    func toggleHaptic(_ isOn: Bool) -> some View {
        onChange(of: isOn) { _, newValue in
            newValue ? Haptics.toggleOn() : Haptics.toggleOff()
        }
    }
}
