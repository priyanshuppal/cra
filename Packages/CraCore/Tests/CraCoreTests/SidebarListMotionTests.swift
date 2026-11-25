import CoreGraphics
import CraCore
import Foundation
import Testing

/// A closed row is gone before the rows below slide onto it, so their titles never draw over
/// its half-faded one.
struct SidebarListMotionTests {
    /// The first millisecond at which the staying rows have covered `share` of their travel.
    static func time(toTravel share: Double) -> TimeInterval {
        (0...1000).map { Double($0) / 1000 }.first { SidebarListMotion.travel(at: $0) >= share }!
    }

    /// Rows are 40 pt tall and 1 pt apart; a title's line is about 16 pt. The next row's title
    /// reaches the leaving one's once it has come (41 - 16) / 41 of the way.
    static let titlesMeet = (41.0 - 16) / 41

    @Test func pinsTheTimings() {
        #expect(SidebarListMotion.duration == 0.22)
        let c = SidebarListMotion.curve
        #expect([c.0, c.1, c.2, c.3] == [0.2, 0.9, 0.25, 1])
        #expect(SidebarListMotion.removedFadeDuration == 0.06)
    }

    @Test func leavingRowIsGoneBeforeItsNeighboursAreHalfway() {
        let halfway = Self.time(toTravel: 0.5)
        #expect(halfway > 0.02 && halfway < 0.03, "the snappy curve is halfway after about 27 ms")
        #expect(SidebarListMotion.leavingOpacity(at: halfway) < 0.1)
        #expect(SidebarListMotion.leavingOpacity(at: Self.time(toTravel: Self.titlesMeet)) < 0.05)
    }

    @Test func fadingOverTheShiftsDurationLeavesHalfTheRowWhereTheNextOneLands() {
        // What the list did before: the leaving row faded on the staying rows' own timing.
        let halfway = Self.time(toTravel: 0.5)
        let old = 1 - SidebarMotion.progress(at: halfway, curve: SidebarListMotion.curve, duration: SidebarListMotion.duration)
        #expect(old > 0.45)
    }

    @Test func leavingRowFinishesWellBeforeTheShift() {
        #expect(SidebarListMotion.removedFadeDuration < SidebarListMotion.duration / 2)
        #expect(SidebarListMotion.leavingOpacity(at: 0) == 1)
        #expect(SidebarListMotion.leavingOpacity(at: SidebarListMotion.removedFadeDuration) < 1e-9)
    }

    @Test(arguments: 0...4) func arrivingRowsFadeInWhereTheyLand(depth: Int) {
        #expect(SidebarListMotion.insertOffset(depth: depth) == 0)
    }
}
