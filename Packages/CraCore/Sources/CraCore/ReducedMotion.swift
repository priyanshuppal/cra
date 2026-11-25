import Foundation

/// What a motion becomes with System Settings ▸ Accessibility ▸ Display ▸ Reduce motion on, as Arc's
/// `AnimationRespectingReduceMotionModifier` and its `respectReduceMotion` views do it: nothing moves across the
/// screen any more, a change of content still reads as one, and colour stays. A swipe that tracks the fingers is
/// not a motion here: it follows them 1:1 either way, and only what plays after the release is substituted.
/// With Reduce motion off every motion plays as it does in Arc.
public enum ReducedMotion {
    public enum Motion: CaseIterable, Sendable {
        /// Something travelling across the window: the sidebar's ⌘S slide, a space settling after a swipe.
        case slide
        /// The same travel on a spring that overshoots: the floating sidebar, a toast arriving.
        case spring
        /// A scale from or into a point: Peek opening out of its link, a menu popping.
        case zoom
        /// A decorative object flying from one place to another: a download to its button.
        case flight
        /// A decorative overshoot that changes nothing: the command bar's scope bounce, a drop's pop.
        case bounce
        /// Colour or opacity changing in place.
        case fade
    }

    public enum Substitute: Equatable, Sendable {
        /// Plays as it would without Reduce motion.
        case asIs
        /// The move is dropped and the old and new content dissolve into each other over this many seconds.
        case crossfade(TimeInterval)
        /// Jumps straight to the end.
        case instant
    }

    /// The dissolve that stands in for a move. Short enough not to slow anything down, long enough to show that
    /// something changed (Apple's own Reduce motion dissolves run about this long).
    public static let crossfadeDuration: TimeInterval = 0.15

    /// `contentChanges`: something appears, disappears or is replaced (the sidebar coming out, Peek opening).
    /// A move that only repositions what is already showing has nothing to dissolve and becomes instant.
    public static func substitute(_ motion: Motion, reduce: Bool, contentChanges: Bool = true) -> Substitute {
        guard reduce else { return .asIs }
        switch motion {
        case .slide, .spring, .zoom: return contentChanges ? .crossfade(crossfadeDuration) : .instant
        case .fade: return .asIs
        case .flight, .bounce: return .instant
        }
    }
}

public extension ReducedMotion.Substitute {
    /// The motion plays unchanged.
    var plays: Bool { self == .asIs }

    /// How long a site that only knows a duration animates: its own with `.asIs`, the dissolve's, or none.
    func duration(_ normal: TimeInterval) -> TimeInterval {
        switch self {
        case .asIs: return normal
        case .crossfade(let d): return d
        case .instant: return 0
        }
    }
}
