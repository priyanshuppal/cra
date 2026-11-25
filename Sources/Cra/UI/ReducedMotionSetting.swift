import AppKit

extension ReducedMotion {
    /// Set by `cra://debug?reduceMotion=1|0` so a scenario can turn Reduce motion on without System Settings;
    /// nil follows the Mac.
    static var debugOverride: Bool?

    /// System Settings ▸ Accessibility ▸ Display ▸ Reduce motion, read when a motion starts (Arc reads it the same
    /// way, `accessibilityDisplayShouldReduceMotion`), so turning it on applies to the next one.
    static var isOn: Bool { debugOverride ?? NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    /// What `motion` becomes on this Mac now (CraCore's `substitute`).
    static func now(_ motion: Motion, contentChanges: Bool = true) -> Substitute {
        substitute(motion, reduce: isOn, contentChanges: contentChanges)
    }
}

extension NSView {
    /// Reduce motion's stand-in for a move: whatever this view's layer tree changes to in the current transaction
    /// dissolves in over `duration` instead of jumping or travelling.
    func dissolveNextChange(_ duration: TimeInterval) {
        guard duration > 0, let layer else { return }
        let fade = CATransition()
        fade.type = .fade
        fade.duration = duration
        layer.add(fade, forKey: "reduceMotionDissolve")
    }
}
