import CraCore
import Foundation
import Testing

/// Arc 1.174.3's `ARCUI.SpringAnimationStyle`, as read from its arm64 slice. The response table is
/// at 0x103725f98 and the damping-ratio table at 0x103725fd0, eight bytes a case in declaration
/// order; `SpringAnimationStyle.properties` (0x100a12870) and the SwiftUI path (0x100a12890, which
/// tail-calls `Animation.spring(response:dampingFraction:blendDuration:)`) both read them.
struct ArcSpringTests {
    @Test func casesAreArcsInItsOrder() {
        // Field descriptor 0x103ea9280: seven empty cases, no payloads.
        #expect(ArcSpring.allCases == [.firm, .firmSlow, .firmExtraSlow, .firmFast,
                                       .springy, .springyFast, .springyExtraFast])
    }

    @Test func presetsAreArcsNumbers() {
        // (response @ 0x103725f98 + 8·i, damping ratio @ 0x103725fd0 + 8·i)
        let expected: [(ArcSpring, Double, Double)] = [
            (.firm, 0.25, 0.9),              // 0x103725f98, 0x103725fd0
            (.firmSlow, 0.35, 0.9),          // 0x103725fa0, 0x103725fd8
            (.firmExtraSlow, 1.25, 0.9),     // 0x103725fa8, 0x103725fe0
            (.firmFast, 0.15, 0.95),         // 0x103725fb0, 0x103725fe8
            (.springy, 0.28, 0.63),          // 0x103725fb8, 0x103725ff0
            (.springyFast, 0.18, 0.8),       // 0x103725fc0, 0x103725ff8
            (.springyExtraFast, 0.08, 0.8),  // 0x103725fc8, 0x103726000
        ]
        for (spring, response, ratio) in expected {
            #expect(spring.response == response)
            #expect(spring.dampingRatio == ratio)
        }
    }

    @Test func coreAnimationTermsFollowArcsConversion() {
        // ARCUI's CASpringAnimation(dampingRatio:frequencyResponse:) at 0x100a12730:
        // stiffness = (2π / response)² · mass, damping = 4π · ratio · mass / response.
        let expected: [(ArcSpring, Double, Double)] = [
            (.firm, 631.65, 45.239),
            (.firmSlow, 322.27, 32.314),
            (.firmExtraSlow, 25.27, 9.048),
            (.firmFast, 1754.6, 79.587),
            (.springy, 503.55, 28.274),
            (.springyFast, 1218.47, 55.851),
            (.springyExtraFast, 6168.5, 125.664),
        ]
        for (spring, stiffness, damping) in expected {
            #expect(abs(spring.stiffness - stiffness) < 0.01)
            #expect(abs(spring.damping - damping) < 0.001)
        }
    }

    @Test func peekButtonsAlreadyRideTwoPresets() {
        // PeekControlLook's springs were read from Arc's ModalButtonStyle before the presets were
        // known; they are firmFast and springy exactly.
        #expect(PeekControlLook.hoverSpring.response == ArcSpring.firmFast.response)
        #expect(PeekControlLook.hoverSpring.dampingFraction == ArcSpring.firmFast.dampingRatio)
        #expect(PeekControlLook.pressSpring.response == ArcSpring.springy.response)
        #expect(PeekControlLook.pressSpring.dampingFraction == ArcSpring.springy.dampingRatio)
    }
}
