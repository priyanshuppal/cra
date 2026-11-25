import Foundation

/// Springs Arc's own controls use, read from Arc 1.174.3's code (docs/arc-reverse-engineering.md,
/// "Springs of Arc's controls"). Each is the pair Arc passes to SwiftUI's `spring(response:dampingFraction:)`;
/// `PeekControlLook.Spring` turns it into Core Animation's stiffness and damping (mass 1), as ARCUI does.
public enum ArcControlSpring {
    /// The toast scaling in from its top centre: `Toasts.ToastWindow.ToastAnimator` sets
    /// `ShinyToastAnimationState.showing` inside `withAnimation` with this spring (0x1019024c0), and
    /// `ScaleInEffect` scales the pill by that progress around (0.5 w, 0.1 h).
    public static let toast = PeekControlLook.Spring(response: 0.4, dampingFraction: 0.7)
}
