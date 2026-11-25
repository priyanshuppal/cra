import Foundation

/// When a drag that snaps plays its tick: as it catches, not while it stays caught or as it lets
/// go. Arc's split divider plays a generic tick, now, as its PaneResizeState turns isCenterSnapped
/// on (ARCUI/SplitViewController.swift, `handle(_:didResize:and:paneResizeState:)`, Arc 1.174.3);
/// the sidebar's edge does the same at 228 pt.
public enum SnapTick {
    public static func fires(was: Bool, now: Bool) -> Bool { now && !was }
}
