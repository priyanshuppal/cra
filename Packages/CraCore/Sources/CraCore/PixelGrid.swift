import CoreGraphics

/// Where sidebar text, favicons and row accessories land on the display's pixels. Rows centre their
/// parts with `/ 2`, so a row with a subtitle put its title at (40 − 16 − 1 − 14) / 2 = 4.5 pt: on a
/// 1x display the text layer was resampled between two pixels and went soft. Arc snaps with
/// `backingAlignedRect:options:` (Arc 1.174.3 and its ArcCore both reference it); Cra rounds each edge
/// to the nearest pixel here, in window space, so a part whose size is whole pixels keeps its size and
/// moves by at most half a pixel (0.5 pt at 1x, 0.25 pt at 2x).
public enum PixelGrid {
    /// `rect` with each edge on the nearest whole pixel at `scale` (pixels per point). Both edges
    /// round the same way at a tie (away from zero), so the size of a part a whole number of pixels
    /// wide or tall never changes.
    public static func align(_ rect: CGRect, scale: CGFloat) -> CGRect {
        guard scale > 0, !rect.isNull, !rect.isInfinite else { return rect }
        let r = rect.standardized
        func px(_ v: CGFloat) -> CGFloat { (v * scale).rounded() / scale }
        let minX = px(r.minX), minY = px(r.minY)
        return CGRect(x: minX, y: minY, width: px(r.maxX) - minX, height: px(r.maxY) - minY)
    }

    /// The indices of `frames` (in window space) whose origin is not on a whole pixel at `scale`:
    /// what `cra://debug?offGrid` lists.
    public static func offGrid(_ frames: [CGRect], scale: CGFloat) -> [Int] {
        frames.indices.filter { i in
            let o = frames[i].standardized.origin
            return [o.x, o.y].contains { v in abs(v * scale - (v * scale).rounded()) > 0.01 }
        }
    }
}
