import CoreGraphics

/// The pill in a split's gap: black on a light space, white on a dark one. Arc's
/// `SplitViewDraggerHandleView.ViewState` carries `contentOverBackgroundAppearance` next to
/// `isHandleVisible`, so its handle follows the backdrop; a black pill on a dark space was lost.
public enum SplitDraggerPill {
    /// Grey level and alpha: 0.28 at rest (the drop region's pill), 0.45 while its divider is dragged.
    public static func tone(dark: Bool, highlighted: Bool) -> (white: CGFloat, alpha: CGFloat) {
        (dark ? 1 : 0, highlighted ? 0.45 : 0.28)
    }
}
