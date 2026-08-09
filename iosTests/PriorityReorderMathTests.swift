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
