import CoreGraphics
import CraCore
import Foundation
import Testing

struct SnapTickTests {
    /// Entering the snap ticks once; staying in it, leaving it or staying out doesn't.
    @Test(arguments: [(false, true, true), (true, true, false), (true, false, false), (false, false, false)])
    func ticksOnlyAsItCatches(was: Bool, now: Bool, fires: Bool) {
        #expect(SnapTick.fires(was: was, now: now) == fires)
    }

    /// A divider dragged through 50/50 of a two-pane split: one tick as it catches the middle,
    /// none for the steps it holds there, none as it lets go, and one more when it comes back.
    @Test func aDragThroughTheMiddleTicksEachTimeItCatches() {
        let a = UUID(), b = UUID()
        let layout = SplitPaneLayout(panes: [.init(id: a, factor: 0.4), .init(id: b, factor: 0.6)],
                                     orientation: .horizontal, containerSize: CGSize(width: 1000, height: 600))
        var was = false
        var ticks = 0
        for delta: CGFloat in [20, 60, 90, 95, 100, 140, 96, 40] {
            let now = layout.dragging(dividerAfter: 0, by: delta).snapped
            if SnapTick.fires(was: was, now: now) { ticks += 1 }
            was = now
        }
        #expect(ticks == 2)
    }
}
