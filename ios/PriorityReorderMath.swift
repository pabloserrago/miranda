import Foundation

/// Pure math for the long-press drag-to-reorder gesture, shared by the live
/// drag (haptic tick when the projected slot changes) and the final commit
/// so the two can never disagree.
enum PriorityReorderMath {
    /// Maps a vertical drag translation to the index the card would land on,
    /// rounding to the nearest row and clamping to the list bounds.
    static func targetIndex(sourceIndex: Int, translationHeight: CGFloat, rowStride: CGFloat, count: Int) -> Int {
        guard count > 1 else { return sourceIndex }
        let delta = Int((translationHeight / rowStride).rounded())
        return min(max(0, sourceIndex + delta), count - 1)
    }
}
