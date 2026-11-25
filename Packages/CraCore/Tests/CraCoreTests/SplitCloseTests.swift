import CraCore
import Testing

/// Closing the focused pane of a split focuses its neighbour, not the first pane.
struct SplitCloseTests {
    @Test(arguments: [
        // [A B C]: A closes → B (now 0); B closes → C (now 1); C closes → B (the last left).
        (0, 2, 0), (1, 2, 1), (2, 2, 1),
        // [A B C D]: the third closes → the fourth, which slides into its place.
        (2, 3, 2), (3, 3, 2),
        // [A B]: either closes → the one left.
        (0, 1, 0), (1, 1, 0),
    ])
    func theNeighbourTakesFocus(closing: Int, remaining: Int, focused: Int) {
        #expect(SplitClose.successor(closingIndex: closing, remaining: remaining) == focused)
    }

    @Test func nothingLeftFocusesNothing() {
        #expect(SplitClose.successor(closingIndex: 0, remaining: 0) == nil)
    }
}
