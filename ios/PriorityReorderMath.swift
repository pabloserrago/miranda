import Foundation

/// Pure math for the long-press drag-to-reorder gesture, shared by the live
/// drag (haptic tick when the projected slot changes) and the final commit
/// so the two can never disagree.
enum PriorityReorderMath {
    /// Maps a vertical drag translation to the index the card would land on,
    /// rounding to the nearest row and clamping to the list bounds.
    /// Fallback for when per-row heights have not been measured yet.
    static func targetIndex(sourceIndex: Int, translationHeight: CGFloat, rowStride: CGFloat, count: Int) -> Int {
        guard count > 1 else { return sourceIndex }
        let delta = Int((translationHeight / rowStride).rounded())
        return min(max(0, sourceIndex + delta), count - 1)
    }

    /// Measured-heights variant: the slot changes exactly when the dragged
    /// card passes the midpoint of a neighboring row, so haptic ticks align
    /// with the visible crossing even when cards have different heights.
    static func targetIndex(sourceIndex: Int, translationHeight: CGFloat, rowHeights: [CGFloat]) -> Int {
        let count = rowHeights.count
        guard count > 1, sourceIndex >= 0, sourceIndex < count else { return sourceIndex }
        var target = sourceIndex
        var crossed: CGFloat = 0
        if translationHeight > 0 {
            var next = sourceIndex + 1
            while next < count, translationHeight > crossed + rowHeights[next] / 2 {
                crossed += rowHeights[next]
                target = next
                next += 1
            }
        } else if translationHeight < 0 {
            var next = sourceIndex - 1
            while next >= 0, -translationHeight > crossed + rowHeights[next] / 2 {
                crossed += rowHeights[next]
                target = next
                next -= 1
            }
        }
        return target
    }

    /// Vertical offset a non-lifted row adopts during the live shuffle: rows
    /// between the source slot and the projected target part by the lifted
    /// card's height so the drop gap is always visible.
    static func shuffleOffset(rowIndex: Int, sourceIndex: Int, targetIndex: Int, liftedHeight: CGFloat) -> CGFloat {
        guard rowIndex != sourceIndex, targetIndex != sourceIndex else { return 0 }
        if targetIndex > sourceIndex, rowIndex > sourceIndex, rowIndex <= targetIndex {
            return -liftedHeight
        }
        if targetIndex < sourceIndex, rowIndex >= targetIndex, rowIndex < sourceIndex {
            return liftedHeight
        }
        return 0
    }

    /// Translation at which the lifted card visually occupies its target slot:
    /// the signed sum of the row heights it passed over. Committing the array
    /// reorder at this translation produces a pixel-identical layout.
    static func settleTranslation(sourceIndex: Int, targetIndex: Int, rowHeights: [CGFloat]) -> CGFloat {
        let count = rowHeights.count
        guard sourceIndex != targetIndex,
              sourceIndex >= 0, sourceIndex < count,
              targetIndex >= 0, targetIndex < count else { return 0 }
        if targetIndex > sourceIndex {
            return rowHeights[(sourceIndex + 1)...targetIndex].reduce(0, +)
        }
        return -rowHeights[targetIndex...(sourceIndex - 1)].reduce(0, +)
    }
}
