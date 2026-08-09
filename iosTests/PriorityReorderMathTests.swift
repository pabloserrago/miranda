import Foundation
import Testing
@testable import ios

struct PriorityReorderMathTests {
    private let stride: CGFloat = 125

    @Test func roundsToNearestRow() {
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 125, rowStride: stride, count: 3) == 1)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 250, rowStride: stride, count: 3) == 2)
        // 63pt is past the halfway point of a 125pt row, so it rounds to the next slot.
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 63, rowStride: stride, count: 3) == 1)
    }

    @Test func smallDragStaysPut() {
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 1, translationHeight: 0, rowStride: stride, count: 3) == 1)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 1, translationHeight: 62, rowStride: stride, count: 3) == 1)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 1, translationHeight: -62, rowStride: stride, count: 3) == 1)
    }

    @Test func negativeDragMovesUp() {
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 2, translationHeight: -125, rowStride: stride, count: 3) == 1)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 2, translationHeight: -250, rowStride: stride, count: 3) == 0)
    }

    @Test func clampsAtBottom() {
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 1, translationHeight: 1000, rowStride: stride, count: 3) == 2)
    }

    @Test func clampsAtTop() {
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 1, translationHeight: -1000, rowStride: stride, count: 3) == 0)
    }

    @Test func singleCardNeverMoves() {
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 500, rowStride: stride, count: 1) == 0)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 500, rowStride: stride, count: 0) == 0)
    }
}

/// Measured-heights variant: the slot changes when the dragged card passes the
/// midpoint of the neighboring row, so haptics align with the visual crossing.
struct PriorityReorderMeasuredHeightsTests {
    private let uniform: [CGFloat] = [190, 190, 190]

    @Test func uniformRowsTickAtMidpoints() {
        // Moving down from index 0: boundary into slot 1 is half of row 1 (95pt).
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 94, rowHeights: uniform) == 0)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 96, rowHeights: uniform) == 1)
        // Boundary into slot 2 is row 1 plus half of row 2 (190 + 95 = 285pt).
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 284, rowHeights: uniform) == 1)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 286, rowHeights: uniform) == 2)
        // Moving up from index 2 mirrors the same boundaries.
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 2, translationHeight: -94, rowHeights: uniform) == 2)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 2, translationHeight: -96, rowHeights: uniform) == 1)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 2, translationHeight: -286, rowHeights: uniform) == 0)
    }

    @Test func variableHeightsUseEachRowsMidpoint() {
        // Middle card is a tall 4-line note.
        let heights: [CGFloat] = [190, 320, 190]
        // From 0 going down: boundary into slot 1 is half of the tall row (160pt).
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 159, rowHeights: heights) == 0)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 161, rowHeights: heights) == 1)
        // Into slot 2: tall row plus half of last row (320 + 95 = 415pt).
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 414, rowHeights: heights) == 1)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 416, rowHeights: heights) == 2)
        // From 2 going up: boundary into slot 1 is half of the tall row (160pt).
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 2, translationHeight: -159, rowHeights: heights) == 2)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 2, translationHeight: -161, rowHeights: heights) == 1)
    }

    @Test func clampsAndSingleCard() {
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 1, translationHeight: 5000, rowHeights: uniform) == 2)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 1, translationHeight: -5000, rowHeights: uniform) == 0)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 500, rowHeights: [190]) == 0)
        #expect(PriorityReorderMath.targetIndex(sourceIndex: 0, translationHeight: 500, rowHeights: []) == 0)
    }
}

/// Live shuffle: how non-lifted rows part around the drag, and where the
/// lifted card settles on drop.
struct PriorityReorderShuffleTests {
    private let heights: [CGFloat] = [190, 320, 190]

    @Test func shuffleOffsetMovesOnlyRowsBetweenSourceAndTarget() {
        // Dragging row 0 down to slot 2: rows 1 and 2 slide up by the lifted height.
        #expect(PriorityReorderMath.shuffleOffset(rowIndex: 1, sourceIndex: 0, targetIndex: 2, liftedHeight: 190) == -190)
        #expect(PriorityReorderMath.shuffleOffset(rowIndex: 2, sourceIndex: 0, targetIndex: 2, liftedHeight: 190) == -190)
        // Dragging row 0 down to slot 1: row 2 stays put.
        #expect(PriorityReorderMath.shuffleOffset(rowIndex: 1, sourceIndex: 0, targetIndex: 1, liftedHeight: 190) == -190)
        #expect(PriorityReorderMath.shuffleOffset(rowIndex: 2, sourceIndex: 0, targetIndex: 1, liftedHeight: 190) == 0)
        // Dragging row 2 up to slot 0: rows 0 and 1 slide down.
        #expect(PriorityReorderMath.shuffleOffset(rowIndex: 0, sourceIndex: 2, targetIndex: 0, liftedHeight: 190) == 190)
        #expect(PriorityReorderMath.shuffleOffset(rowIndex: 1, sourceIndex: 2, targetIndex: 0, liftedHeight: 190) == 190)
        // No projected move: everything stays.
        #expect(PriorityReorderMath.shuffleOffset(rowIndex: 1, sourceIndex: 0, targetIndex: 0, liftedHeight: 190) == 0)
        // The lifted row itself is never offset by the shuffle.
        #expect(PriorityReorderMath.shuffleOffset(rowIndex: 0, sourceIndex: 0, targetIndex: 2, liftedHeight: 190) == 0)
    }

    @Test func settleTranslationSumsCrossedHeights() {
        // Down: the crossed rows are everything after the source up to the target.
        #expect(PriorityReorderMath.settleTranslation(sourceIndex: 0, targetIndex: 1, rowHeights: heights) == 320)
        #expect(PriorityReorderMath.settleTranslation(sourceIndex: 0, targetIndex: 2, rowHeights: heights) == 510)
        // Up: negative sum of the rows passed over.
        #expect(PriorityReorderMath.settleTranslation(sourceIndex: 1, targetIndex: 0, rowHeights: heights) == -190)
        #expect(PriorityReorderMath.settleTranslation(sourceIndex: 2, targetIndex: 0, rowHeights: heights) == -510)
        // No move settles back to the origin.
        #expect(PriorityReorderMath.settleTranslation(sourceIndex: 1, targetIndex: 1, rowHeights: heights) == 0)
        // Out-of-range indices are a no-op rather than a crash.
        #expect(PriorityReorderMath.settleTranslation(sourceIndex: 0, targetIndex: 5, rowHeights: heights) == 0)
    }
}
