import CoreGraphics

/// Arc's stand-in for a page with no favicon yet: a faint rounded square, not a globe.
///
/// Arc 1.174.3 draws it from `FaviconBackground` in `ARC_Favicons.bundle` (rendition
/// `EmptyFavicon-white.svg`): an opaque white 14 × 14 pt square (28 × 28 px at 2x) whose
/// corners match a continuous corner of radius 3.6 pt best (3.5 and 3.7 are close; 3.0 and
/// 4.5 are not). The asset has no dark or light variant, so the faintness comes from the
/// tint: white at 14 % on a dark fill and black at 10 % on a light one, as measured in Arc's tab
/// switcher. Arc's back/forward menu draws the same square white at 35 % on its dark menu.
///
/// The sidebar, the tab switcher and the back/forward menu all read these, so they can't drift.
public enum FaviconPlaceholder {
    /// The square's side in Arc's 16 pt favicon slot.
    public static let side: CGFloat = 14
    /// The favicon slot the square was measured in.
    public static let slot: CGFloat = 16
    public static let cornerRadius: CGFloat = 3.6
    /// The back/forward menu's square, white on the menu's dark fill.
    public static let menuAlpha: CGFloat = 0.35

    /// The tint's grey: white on a dark fill, black on a light one.
    public static func white(dark: Bool) -> CGFloat { dark ? 1 : 0 }

    /// The tint's alpha: 14 % white on a dark fill, 10 % black on a light one.
    public static func alpha(dark: Bool) -> CGFloat { dark ? 0.14 : 0.10 }

    /// The square centred in a favicon slot of `size` points, scaled with it (14 in 16).
    public static func frame(inSlot size: CGFloat) -> CGRect {
        let s = side * size / slot
        let inset = (size - s) / 2
        return CGRect(x: inset, y: inset, width: s, height: s)
    }

    /// The corner radius for a slot of `size` points, scaled like the square.
    public static func cornerRadius(inSlot size: CGFloat) -> CGFloat {
        cornerRadius * size / slot
    }
}
