import CraCore
import Foundation
import Testing

/// A dragged divider resizes the page windows at most 30 times a second, and always with the
/// frame it was let go at.
@Suite struct PaneResizeThrottleTests {
    /// Applies `times` (seconds, the events' own) and returns which resized the pages, then the flush.
    static func run(_ times: [TimeInterval]) -> (applied: [Bool], flushed: Bool) {
        var t = PaneResizeThrottle()
        let applied = times.map { t.shouldApply(now: $0) }
        return (applied, t.flush())
    }

    @Test func theFirstEventApplies() {
        let r = Self.run([100])
        #expect(r.applied == [true])
        #expect(!r.flushed)
    }

    @Test func eventsCloserThanTheIntervalCoalesce() {
        // Seven events within 33 ms, as the scenario sends: the first, then the flush.
        let times = (0..<7).map { 100 + Double($0) * 0.004 }
        let r = Self.run(times)
        #expect(r.applied == [true, false, false, false, false, false, false])
        #expect(r.flushed)
        #expect(r.applied.filter { $0 }.count + (r.flushed ? 1 : 0) <= 2)
    }

    @Test func oneEventPerIntervalApplies() {
        // An event every 10 ms: every fourth, timed from the last applied.
        let times = (0..<12).map { 100 + Double($0) * 0.01 }
        let r = Self.run(times)
        #expect(r.applied == [true, false, false, false, true, false, false, false, true, false, false, false])
        #expect(r.flushed)
    }

    @Test func theIntervalItselfApplies() {
        let r = Self.run([0, PaneResizeThrottle.interval])
        #expect(r.applied == [true, true])
        #expect(!r.flushed)
    }

    @Test func theFinalFrameAlwaysApplies() {
        // The last event was held back: the flush owes it. One that applied owes nothing.
        #expect(Self.run([100, 100.01]).flushed)
        #expect(!Self.run([100, 100.01, 100.05]).flushed)
    }

    @Test func aNewDragStartsAfresh() {
        var t = PaneResizeThrottle()
        #expect(t.shouldApply(now: 100))
        #expect(!t.shouldApply(now: 100.01))
        #expect(t.flush())
        #expect(t.shouldApply(now: 100.02))
        #expect(!t.flush())
    }

    @Test func thirtyASecond() {
        #expect(PaneResizeThrottle.interval == 1.0 / 30)
    }
}
