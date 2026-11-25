import CraCore
import Testing

/// Display links ask for the screen's full rate, never under 60.
@Suite struct FrameRateTests {
    @Test func asksForTheScreensFullRate() {
        #expect(FrameRate.range(maxFPS: 120) == .init(minimum: 60, maximum: 120, preferred: 120), "ProMotion")
        #expect(FrameRate.range(maxFPS: 60) == .init(minimum: 60, maximum: 60, preferred: 60))
        #expect(FrameRate.range(maxFPS: 144) == .init(minimum: 60, maximum: 144, preferred: 144))
    }

    @Test func neverUnder60() {
        #expect(FrameRate.range(maxFPS: 0) == .init(minimum: 60, maximum: 60, preferred: 60), "a screen that reports no rate")
        #expect(FrameRate.range(maxFPS: 30) == .init(minimum: 60, maximum: 60, preferred: 60))
        #expect(FrameRate.range(maxFPS: nil) == .init(minimum: 60, maximum: 120, preferred: 120), "no screen yet: the fallback")
    }
}
