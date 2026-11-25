import CoreGraphics

/// Where a new Little Window opens: centred in the screen's visible area, or 24 pt right of and
/// below the Little Window in front when one is showing there, so the new one doesn't cover it
/// exactly. Only windows a person can see count: a Peek waiting on another tab, a minimised Little
/// Window or one on another display used to push a lone Little Window off the centre by 24 pt each.
/// Cra's frames are AppKit's (y up), so "below" is a smaller y.
public enum LittleWindowPlacement {
    /// The cascade step, right and down.
    public static let step: CGFloat = 24
    /// A window larger than the visible area is cut to it, less this much.
    public static let inset: CGFloat = 40

    /// `others`: the frames of the Little Windows (not Peeks) shown and not minimised on this screen,
    /// front to back. The result stays inside `visible`.
    public static func frame(size: CGSize, visible: CGRect, others: [CGRect]) -> CGRect {
        let w = min(size.width, visible.width - inset), h = min(size.height, visible.height - inset)
        var f = CGRect(x: visible.midX - w / 2, y: visible.midY - h / 2, width: w, height: h)
        if let front = others.first {
            // Its top-left corner a step off the front one's.
            f.origin = CGPoint(x: front.minX + step, y: front.maxY - step - h)
        }
        f.origin.x = min(max(visible.minX, f.origin.x), visible.maxX - w)
        f.origin.y = min(max(visible.minY, f.origin.y), visible.maxY - h)
        return f
    }
}
