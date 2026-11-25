import CraCore
import Foundation
import Testing

/// A pane's Split View menu (the pane toolbar's), after Arc 1.172.2 read live over AX and Arc's
/// `SplitViewPaneMenuOperation` (docs/arc-reverse-engineering.md, Commands and Expand Current Split).
struct SplitPaneMenuTests {
    static func titles(_ rows: [SplitPaneMenu.Row], _ o: SplitOrientation) -> [String] { rows.map { $0.op.title(o) } }
    static func enabled(_ rows: [SplitPaneMenu.Row], _ op: SplitPaneMenu.Operation) -> Bool? { rows.first { $0.op == op }?.enabled }

    @Test func theOrderIsArcs() {
        let rows = SplitPaneMenu.rows(index: 0, count: 2, orientation: .horizontal, limit: 4)
        #expect(Self.titles(rows, .horizontal) == [
            "Move Left", "Move Right", "Add Right Split", "Add Left Split", "Separate Tab from Split",
            "Convert to Vertical Split View", "Share Split View…", "Copy Link", "Close this Split Pane",
        ])
        #expect(rows.filter(\.op.startsGroup).map(\.op) == [.copyLink, .close])
    }

    @Test func aStackedSplitSaysUpDownTopBottom() {
        let rows = SplitPaneMenu.rows(index: 1, count: 3, orientation: .vertical, limit: 4)
        #expect(Self.titles(rows, .vertical) == [
            "Move Up", "Move Down", "Add Bottom Split", "Add Top Split", "Separate Tab from Split",
            "Convert to Horizontal Split View", "Share Split View…", "Copy Link", "Close this Split Pane",
        ])
        #expect(rows.map(\.enabled).allSatisfy { $0 })
        #expect(SplitPaneMenu.Operation.addPaneBottom.addsAfter == true)
        #expect(SplitPaneMenu.Operation.addPaneTop.addsAfter == false)
    }

    @Test func theFirstPaneCantMoveLeftAndTheLastCantMoveRight() {
        let first = SplitPaneMenu.rows(index: 0, count: 3, orientation: .horizontal, limit: 4)
        #expect(Self.enabled(first, .moveLeft) == false)
        #expect(Self.enabled(first, .moveRight) == true)
        let last = SplitPaneMenu.rows(index: 2, count: 3, orientation: .horizontal, limit: 4)
        #expect(Self.enabled(last, .moveLeft) == true)
        #expect(Self.enabled(last, .moveRight) == false)
        let middle = SplitPaneMenu.rows(index: 1, count: 3, orientation: .horizontal, limit: 4)
        #expect(Self.enabled(middle, .moveLeft) == true && Self.enabled(middle, .moveRight) == true)
    }

    @Test func addIsGreyedOutAtThePaneLimit() {
        let full = SplitPaneMenu.rows(index: 1, count: 4, orientation: .horizontal, limit: SplitPaneLimit.maximum(morePanes: false))
        #expect(Self.enabled(full, .addPaneRight) == false)
        #expect(Self.enabled(full, .addPaneLeft) == false)
        let more = SplitPaneMenu.rows(index: 1, count: 4, orientation: .horizontal, limit: SplitPaneLimit.maximum(morePanes: true))
        #expect(Self.enabled(more, .addPaneRight) == true)
        #expect(Self.enabled(more, .addPaneLeft) == true)
        let stackedFull = SplitPaneMenu.rows(index: 0, count: 8, orientation: .vertical, limit: 8)
        #expect(Self.enabled(stackedFull, .addPaneBottom) == false)
        #expect(Self.enabled(stackedFull, .addPaneTop) == false)
    }

    /// moveWithinSplit counts the slot before the pane leaves it, so one place right is two on.
    @Test func moveTargetsAreOnePlaceOver() {
        func move(_ panes: [String], _ i: Int, _ op: SplitPaneMenu.Operation) -> [String] {
            var p = panes
            guard let to = SplitPaneMenu.moveTarget(op, from: i) else { return p }
            let x = p.remove(at: i)
            p.insert(x, at: min(max(0, i < to ? to - 1 : to), p.count))
            return p
        }
        #expect(move(["a", "b", "c"], 0, .moveRight) == ["b", "a", "c"])
        #expect(move(["a", "b", "c"], 1, .moveRight) == ["a", "c", "b"])
        #expect(move(["a", "b", "c"], 2, .moveLeft) == ["a", "c", "b"])
        #expect(move(["a", "b", "c"], 1, .moveLeft) == ["b", "a", "c"])
        #expect(SplitPaneMenu.moveTarget(.separate, from: 1) == nil)
    }
}
