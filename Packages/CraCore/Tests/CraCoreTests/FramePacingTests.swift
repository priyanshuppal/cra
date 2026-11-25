import CraCore
import Foundation
import Testing

/// The ⌘S slide's frame-pacing readout: frames drawn, the display's rate, frames missed and the longest gap.
struct FramePacingTests {
    static func ticks(_ times: [TimeInterval], interval: TimeInterval) -> FramePacing {
        var p = FramePacing()
        for t in times { p.record(timestamp: t, interval: interval) }
        return p
    }

    /// At 120 Hz a 25 ms gap is three intervals: two frames that weren't drawn.
    @Test func aLongGapAt120HzCountsTheFramesItSkipped() {
        let f = 1.0 / 120
        let p = Self.ticks([10, 10 + f, 10 + 2 * f, 10 + 2 * f + 0.025, 10 + 3 * f + 0.025], interval: f)
        #expect(p.frames == 5)
        #expect(p.missed == 2)
        #expect(p.hz == 120)
        #expect(p.longestGapMs == 25)
    }

    /// Every frame on time at 60 Hz: none missed, the longest gap one interval.
    @Test func evenFramesAt60HzMissNone() {
        let f = 1.0 / 60
        let p = Self.ticks((0..<6).map { 5 + Double($0) * f }, interval: f)
        #expect(p.frames == 6)
        #expect(p.missed == 0)
        #expect(p.hz == 60)
        #expect(p.longestGapMs == 17)
    }

    /// The rate is the nearest whole number: a ProMotion interval a hair off 1/120 still reads 120, and 1/59.94 reads 60.
    @Test func theRateRoundsToTheNearestHertz() {
        #expect(Self.ticks([0], interval: 0.00834).hz == 120)
        #expect(Self.ticks([0], interval: 1 / 59.94).hz == 60)
        #expect(Self.ticks([0], interval: 1.0 / 144).hz == 144)
        #expect(FramePacing().hz == 0)
        #expect(FramePacing().missed == 0)
    }

    /// A gap a little over one interval (a late but not skipped frame) misses nothing.
    @Test func aSlightlyLateFrameIsNotAMissedOne() {
        let f = 1.0 / 120
        #expect(Self.ticks([0, f * 1.4, f * 2.4], interval: f).missed == 0)
        #expect(Self.ticks([0, f * 1.6], interval: f).missed == 1)
    }
}
