import CoreGraphics
import CraCore
import Foundation
import Testing

/// A drag held near the sidebar list's top or bottom edge scrolls it, faster toward the edge,
/// at the same speed whatever the display's frame rate.
@Suite struct DragAutoscrollTests {
    typealias A = DragAutoscroll

    @Test func speedRampsTowardEachEdge() {
        let b = A.band, m = A.maxSpeed
        #expect(A.speed(fromTop: 0, fromBottom: 400) == -m, "at the top edge: full speed up")
        #expect(A.speed(fromTop: b / 2, fromBottom: 400) == -m / 2)
        #expect(A.speed(fromTop: b, fromBottom: 400) == 0, "the band's inner end")
        #expect(A.speed(fromTop: 200, fromBottom: 200) == 0, "the list's middle")
        #expect(A.speed(fromTop: 400, fromBottom: b / 4) == m * 3 / 4)
        #expect(A.speed(fromTop: 400, fromBottom: 0) == m, "at the bottom edge: full speed down")
        #expect(A.speed(fromTop: -1, fromBottom: 400) == 0, "above the list")
        #expect(A.speed(fromTop: 400, fromBottom: -1) == 0, "below the list")
        #expect(A.speed(fromTop: 10, fromBottom: 100, band: 20, max: 100) == -50)
    }

    @Test func stepIsSpeedTimesFrameAtAnyRate() {
        #expect(abs(A.step(speed: 900, dt: 1.0 / 60) - 15) < 1e-9)
        #expect(abs(A.step(speed: 900, dt: 1.0 / 120) - 7.5) < 1e-9)
        #expect(abs(A.step(speed: -600, dt: 1.0 / 120) - -5) < 1e-9)
        // A second's worth of frames covers the same distance at either rate.
        let at60 = (0..<60).reduce(CGFloat(0)) { s, _ in s + A.step(speed: 900, dt: 1.0 / 60) }
        let at120 = (0..<120).reduce(CGFloat(0)) { s, _ in s + A.step(speed: 900, dt: 1.0 / 120) }
        #expect(abs(at60 - 900) < 1e-6)
        #expect(abs(at120 - 900) < 1e-6)
    }

    @Test func aLateOrBackwardFrameIsClamped() {
        #expect(A.step(speed: 900, dt: 1) == 900 * CGFloat(A.maxFrame), "a stalled frame moves at most maxFrame's worth")
        #expect(A.step(speed: 900, dt: -0.01) == 0)
        #expect(A.step(speed: 0, dt: 1.0 / 60) == 0)
    }
}
