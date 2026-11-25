import CoreGraphics
import Foundation

/// How fast a sidebar list scrolls while a drag hovers near its top or bottom edge, so with a
/// long pinned list everything past the fold (Today included) stays in reach. The app's
/// DragAutoscroller moves the list by `step` once per display frame.
public enum DragAutoscroll {
    /// Edge band, and the speed at the very edge in points per second.
    public static let band: CGFloat = 48
    public static let maxSpeed: CGFloat = 900
    /// The longest frame a step covers: a late frame moves the list no more than this much.
    public static let maxFrame: TimeInterval = 0.05

    /// Points per second for a pointer `fromTop` and `fromBottom` points inside the list's edges:
    /// up (negative) in the top band, down in the bottom one, faster toward the edge, else 0.
    public static func speed(fromTop: CGFloat, fromBottom: CGFloat, band: CGFloat = band, max: CGFloat = maxSpeed) -> CGFloat {
        guard band > 0, fromTop >= 0, fromBottom >= 0 else { return 0 }
        if fromTop < band { return -max * (1 - fromTop / band) }
        if fromBottom < band { return max * (1 - fromBottom / band) }
        return 0
    }

    /// How far the list moves in a frame of `dt` seconds: the same speed at 60 Hz and 120 Hz.
    public static func step(speed: CGFloat, dt: TimeInterval) -> CGFloat {
        speed * CGFloat(min(Swift.max(dt, 0), maxFrame))
    }
}
