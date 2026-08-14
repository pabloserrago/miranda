import Testing
import CoreGraphics
@testable import ios

/// The Move Up / Move Down accessibility actions on a priority row are the
/// pointer-free equivalent of the lift-and-drag reorder. Both commit through
/// `PriorityReorderMath.reordered`, so these cover the orderings each action
/// produces and the bounds where an action is not offered.
struct ReorderAccessibilityActionTests {

    private let ids = ["a", "b", "c"]

    @Test func moveUpSwapsWithThePrecedingCard() {
        #expect(PriorityReorderMath.reordered(ids, from: 1, to: 0) == ["b", "a", "c"])
        #expect(PriorityReorderMath.reordered(ids, from: 2, to: 1) == ["a", "c", "b"])
    }

    @Test func moveDownSwapsWithTheFollowingCard() {
        #expect(PriorityReorderMath.reordered(ids, from: 0, to: 1) == ["b", "a", "c"])
        #expect(PriorityReorderMath.reordered(ids, from: 1, to: 2) == ["a", "c", "b"])
    }

    @Test func movingAcrossTheWholeListKeepsEveryCard() {
        #expect(PriorityReorderMath.reordered(ids, from: 0, to: 2) == ["b", "c", "a"])
        #expect(PriorityReorderMath.reordered(ids, from: 2, to: 0) == ["c", "a", "b"])
    }

    @Test func outOfBoundsAndNoOpMovesLeaveTheOrderAlone() {
        #expect(PriorityReorderMath.reordered(ids, from: 1, to: 1) == ids)
        // The row at each end does not publish the action that would land here.
        #expect(PriorityReorderMath.reordered(ids, from: 0, to: -1) == ids)
        #expect(PriorityReorderMath.reordered(ids, from: 2, to: 3) == ids)
        #expect(PriorityReorderMath.reordered(ids, from: 5, to: 0) == ids)
    }

    @Test func aSingleCardListCannotReorder() {
        #expect(PriorityReorderMath.reordered(["a"], from: 0, to: 0) == ["a"])
    }

    @Test func reorderingMatchesWhatADragToTheSameSlotProduces() {
        // A drag that lands on slot 2 and the Move Down action from slot 1 must
        // agree, since the row is the same and only the input path differs.
        let stride: CGFloat = 125
        let dragTarget = PriorityReorderMath.targetIndex(
            sourceIndex: 1, translationHeight: stride, rowStride: stride, count: 3
        )
        #expect(dragTarget == 2)
        #expect(PriorityReorderMath.reordered(ids, from: 1, to: dragTarget)
                == PriorityReorderMath.reordered(ids, from: 1, to: 2))
    }
}
