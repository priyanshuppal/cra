import CoreGraphics
import Foundation

/// How a space's list moves when rows close, archive, open or move.
///
/// The rows that stay slide over `duration` on `curve`: SwiftUI's
/// `.snappy(duration: 0.22, extraBounce: 0)`, Cra's pick from when the list was SwiftUI. That
/// curve puts the rows below a closed tab halfway into its place after 27 ms, so a leaving row
/// that faded over the same 0.22 s was still half there when the next row's title slid onto
/// its own: two titles on top of each other for 2–4 frames. A leaving row now fades over
/// `removedFadeDuration` on the same curve, about 6 % left when its neighbours are halfway,
/// and sits behind them while it goes.
///
/// Arc 1.174.3 (otool, 26 Nov 2026): the sidebar's NSOutlineView diff runs in an
/// NSAnimationContext of 0.12 s with no timing function, between beginUpdates and endUpdates.
/// It removes rows with `.effectFade` (one row) or `[.effectFade, .slideUp]` (several) and
/// inserts them with `.effectFade`: a row arrives in place, it doesn't drop in.
public enum SidebarListMotion {
    public static let duration: TimeInterval = 0.22
    /// The cubic Bézier's control points (CAMediaTimingFunction).
    public static let curve: (Double, Double, Double, Double) = (0.2, 0.9, 0.25, 1)
    /// How long a closed or archived row takes to fade out.
    public static let removedFadeDuration: TimeInterval = 0.06

    /// The share of their travel the staying rows have covered `t` seconds in.
    public static func travel(at t: TimeInterval) -> Double {
        SidebarMotion.progress(at: t, curve: curve, duration: duration)
    }

    /// A leaving row's opacity `t` seconds in.
    public static func leavingOpacity(at t: TimeInterval) -> Double {
        1 - SidebarMotion.progress(at: t, curve: curve, duration: removedFadeDuration)
    }

    /// How far above its place an arriving row starts, at any depth: Arc inserts with
    /// `.effectFade` alone, folder children included, so it fades in where it lands.
    public static func insertOffset(depth: Int) -> CGFloat { 0 }
}
