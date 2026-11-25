import CoreGraphics
import CraCore
import Testing

/// The drop region's gap shows Arc's dragger pill (1.173.1: "a dragger pill in its gap"), and the
/// pill follows the space's appearance (Arc's `contentOverBackgroundAppearance`).
@Suite struct SplitDraggerPillTests {
    /// (region index, panes with the region, the pill's gap)
    static let gaps: [(Int, Int, Int?)] = [
        (1, 2, 0),    // a lone page's right edge: the gap before it
        (0, 2, 0),    // its left edge: the region comes first, so the gap after it
        (0, 3, 0),    // a split's first pane's left side
        (2, 3, 1),    // a split's last pane's right side
        (3, 4, 2),
        (2, 4, 1),    // between two panes: the one before it ([U] in Arc)
        (1, 3, 0),
        (0, 1, nil),  // no other pane, no gap
        (2, 2, nil),  // out of range
        (-1, 3, nil),
    ]

    @Test(arguments: gaps)
    func pillGap(_ c: (Int, Int, Int?)) {
        #expect(SplitDropProposal.pillGap(regionIndex: c.0, count: c.1) == c.2)
    }

    /// (dark space, divider dragged, grey level, alpha)
    static let tones: [(Bool, Bool, CGFloat, CGFloat)] = [
        (false, false, 0, 0.28),
        (false, true, 0, 0.45),
        (true, false, 1, 0.28),
        (true, true, 1, 0.45),
    ]

    @Test(arguments: tones)
    func tone(_ c: (Bool, Bool, CGFloat, CGFloat)) {
        let t = SplitDraggerPill.tone(dark: c.0, highlighted: c.1)
        #expect(t.white == c.2)
        #expect(t.alpha == c.3)
    }
}
