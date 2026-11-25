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
        #expect(!dwell.sample(row: a, at: 10))
        #expect(!dwell.sample(row: a, at: 10.1))
        #expect(!dwell.sample(row: a, at: 10 + SidebarSplitDwell.delay - 0.01))
    }

    @Test func splitOnceItHasStayed() {
        var dwell = SidebarSplitDwell()
        #expect(!dwell.sample(row: a, at: 10))
        #expect(dwell.sample(row: a, at: 10 + SidebarSplitDwell.delay + 0.001))
        // A still pointer keeps getting AppKit's periodic updates: it stays a split.
        #expect(dwell.sample(row: a, at: 11))
    }

    @Test func anotherRowStartsOver() {
        var dwell = SidebarSplitDwell()
        // Dragged down the list: a row every 0.2 s never offers a split.
        let crossing = [(a, 10.0), (a, 10.2), (b, 10.25), (b, 10.45)].map { dwell.sample(row: $0.0, at: $0.1) }
        #expect(crossing == [false, false, false, false])
        #expect(dwell.row == b)
        #expect(dwell.sample(row: b, at: 10.25 + SidebarSplitDwell.delay + 0.001))
    }

    @Test func leavingTheMiddleStartsOver() {
        var dwell = SidebarSplitDwell()
        #expect(!dwell.sample(row: a, at: 10))
        // Off the middle (a gap, a row's edge, a folder) and back onto the same row.
        #expect(!dwell.sample(row: nil, at: 10.2))
        #expect(dwell.since == nil)
        #expect(!dwell.sample(row: a, at: 10.25))
        #expect(!dwell.sample(row: a, at: 10.5))
        #expect(dwell.sample(row: a, at: 10.25 + SidebarSplitDwell.delay + 0.001))
        dwell.reset()
        #expect(dwell.row == nil && dwell.since == nil)
        #expect(!dwell.sample(row: a, at: 12))
    }
}
