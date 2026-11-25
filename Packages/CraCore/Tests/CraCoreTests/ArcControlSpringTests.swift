import CraCore
import Foundation
import Testing

/// The springs of Arc's controls, read from Arc 1.174.3 (docs/arc-reverse-engineering.md).
struct ArcControlSpringTests {
    @Test func theToastIsArcsToastAnimatorSpring() {
        // 0x10190248c: response 0.4 (0x3fd999999999999a), dampingFraction 0.7 (0x3fe6666666666666),
        // blendDuration 0.1, stored once and read by ToastAnimator's withAnimation (0x1018ff5b4, 0x1018ff4a8).
        #expect(ArcControlSpring.toast == PeekControlLook.Spring(response: 0.4, dampingFraction: 0.7))
    }

    @Test func coreAnimationGetsArcsConversion() {
        // ARCUI's CASpringAnimation(dampingRatio:frequencyResponse:) at 0x100a12730:
        // stiffness = (2π / response)², damping = 4π · ratio / response, mass 1.
        let toast = ArcControlSpring.toast
        #expect(abs(toast.stiffness - 246.7401) < 0.001)
        #expect(abs(toast.damping - 21.9911) < 0.001)
        // A damping ratio of 0.7 overshoots by e^(−πζ/√(1−ζ²)) ≈ 4.6 %.
        let zeta = toast.damping / (2 * toast.stiffness.squareRoot())
        #expect(abs(zeta - 0.7) < 1e-9)
        #expect(abs(exp(-Double.pi * zeta / (1 - zeta * zeta).squareRoot()) - 0.0460) < 0.0005)
    }
}
