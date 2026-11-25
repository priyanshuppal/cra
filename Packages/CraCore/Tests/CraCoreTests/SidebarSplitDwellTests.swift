import CraCore
import Foundation
import Testing

/// A tab dragged over another tab's middle offers a split only after it stays there (Arc's
/// `splitDropTargetDelaySatisfied`), so a slow reorder down the list doesn't open the split
/// preview and tick on every row.
struct SidebarSplitDwellTests {
    let a = UUID()
    let b = UUID()

    @Test func noSplitBeforeTheDelay() {
        var dwell = SidebarSplitDwell()
        let r1 = dwell.sample(row: a, at: 10)
        #expect(!r1)
        let r2 = dwell.sample(row: a, at: 10.1)
        #expect(!r2)
        let r3 = dwell.sample(row: a, at: 10 + SidebarSplitDwell.delay - 0.01)
        #expect(!r3)
    }

    @Test func splitOnceItHasStayed() {
        var dwell = SidebarSplitDwell()
        let r4 = dwell.sample(row: a, at: 10)
        #expect(!r4)
        let r5 = dwell.sample(row: a, at: 10 + SidebarSplitDwell.delay + 0.001)
        #expect(r5)
        // A still pointer keeps getting AppKit's periodic updates: it stays a split.
        let r6 = dwell.sample(row: a, at: 11)
        #expect(r6)
    }

    @Test func anotherRowStartsOver() {
        var dwell = SidebarSplitDwell()
        // Dragged down the list: a row every 0.2 s never offers a split.
        let crossing = [(a, 10.0), (a, 10.2), (b, 10.25), (b, 10.45)].map { dwell.sample(row: $0.0, at: $0.1) }
        #expect(crossing == [false, false, false, false])
        #expect(dwell.row == b)
        let r7 = dwell.sample(row: b, at: 10.25 + SidebarSplitDwell.delay + 0.001)
        #expect(r7)
    }

    @Test func leavingTheMiddleStartsOver() {
        var dwell = SidebarSplitDwell()
        let r8 = dwell.sample(row: a, at: 10)
        #expect(!r8)
        // Off the middle (a gap, a row's edge, a folder) and back onto the same row.
        let r9 = dwell.sample(row: nil, at: 10.2)
        #expect(!r9)
        #expect(dwell.since == nil)
        let r10 = dwell.sample(row: a, at: 10.25)
        #expect(!r10)
        let r11 = dwell.sample(row: a, at: 10.5)
        #expect(!r11)
        let r12 = dwell.sample(row: a, at: 10.25 + SidebarSplitDwell.delay + 0.001)
        #expect(r12)
        dwell.reset()
        #expect(dwell.row == nil && dwell.since == nil)
        let r13 = dwell.sample(row: a, at: 12)
        #expect(!r13)
    }
}
