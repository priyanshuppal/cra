import CraCore
import Testing

/// Which fill a sidebar tab row takes: the open tab's, a pick's, or none (Arc's isCurrentItem and
/// isMultiSelected).
struct TabRowHighlightTests {
    struct Row: Sendable, CustomTestStringConvertible {
        var current: Bool
        var picked: Bool
        var picking: Bool
        var expected: TabRowHighlight
        var testDescription: String { "current=\(current) picked=\(picked) picking=\(picking)" }
    }

    @Test(arguments: [
        Row(current: false, picked: false, picking: false, expected: .none),
        Row(current: true, picked: false, picking: false, expected: .current),
        // ⌘-picked tabs: a pick that isn't open takes the multi-select tint, the open one keeps its own look.
        Row(current: false, picked: true, picking: true, expected: .picked),
        Row(current: true, picked: true, picking: true, expected: .current),
        // While tabs are picked, a row outside the picks is bare, the open tab too (Cra's rule before Arc's tones).
        Row(current: false, picked: false, picking: true, expected: .none),
        Row(current: true, picked: false, picking: true, expected: .none),
    ])
    func highlight(_ row: Row) {
        #expect(TabRowHighlight(current: row.current, picked: row.picked, picking: row.picking) == row.expected)
    }

    /// Only the open tab casts Arc's shadow; a pick is flat (TabCellBackgroundMutiselected has no shadow).
    @Test func onlyTheOpenTabIsLifted() {
        #expect(TabRowHighlight.current.lifted)
        #expect(!TabRowHighlight.picked.lifted)
        #expect(!TabRowHighlight.none.lifted)
        #expect(TabRowHighlight.current.filled && TabRowHighlight.picked.filled && !TabRowHighlight.none.filled)
    }
}
