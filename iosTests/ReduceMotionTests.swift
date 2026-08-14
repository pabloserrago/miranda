import Testing
import SwiftUI
@testable import ios

/// The gating seam every animated surface routes through.
struct ReduceMotionTests {

    @Test func animationsSurviveWhenReduceMotionIsOff() {
        #expect(Motion.gated(.spring, reduce: false) != nil)
        #expect(Motion.gated(.easeOut(duration: 0.2), reduce: false) != nil)
    }

    @Test func animationsAreDroppedWhenReduceMotionIsOn() {
        #expect(Motion.gated(.spring, reduce: true) == nil)
        #expect(Motion.gated(.easeOut(duration: 0.2), reduce: true) == nil)
    }

    @Test func anAlreadyNilAnimationStaysNil() {
        #expect(Motion.gated(nil, reduce: false) == nil)
        #expect(Motion.gated(nil, reduce: true) == nil)
    }

    @Test func theEnvironmentValuePassesThroughWithoutTheTestOverride() {
        // No -UITestReduceMotion argument under `xcodebuild test`, so the
        // environment value decides.
        #expect(Motion.isReduced(true))
        #expect(!Motion.isReduced(false))
    }
}

// `Motion.transition` is not covered here: `AnyTransition` is opaque and not
// Equatable, so there is nothing to assert. Its effect is observable in
// `ReduceMotionUITests` instead.
