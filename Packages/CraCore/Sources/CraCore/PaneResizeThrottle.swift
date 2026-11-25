import Foundation

/// How often a dragged split divider resizes the page windows. Each resize makes Chromium lay
/// the page out synchronously, about 5 ms a window, so following every mouse move cost 10–20 ms
/// an event with two to four panes, more than a frame at 120 Hz. Arc throttles the same way
/// (WindowContentViewController's `ContentResizeMode { intrinsic, throttle, locked }` with
/// `pendingResizeFrames`, `resizeTimer` and `contentResizeThrottleSubscription`;
/// SplitViewContentPaneView's `lockContentWidth`). The cards still follow every event; only the
/// pages wait. Times are the events' own (NSEvent.timestamp), not the wall clock.
public struct PaneResizeThrottle: Sendable {
    /// [U] Arc's interval not measured: 30 resizes a second.
    public static let interval: TimeInterval = 1.0 / 30

    public var interval: TimeInterval
    private var lastApplied: TimeInterval?
    /// A frame was held back since the last one applied.
    public private(set) var pending = false

    public init(interval: TimeInterval = PaneResizeThrottle.interval) {
        self.interval = interval
    }

    /// Whether the event at `now` resizes the pages: the first of a drag does, then one at most
    /// per `interval`. One held back stays pending until the next applies or the drag ends.
    public mutating func shouldApply(now: TimeInterval) -> Bool {
        if let last = lastApplied, now - last < interval {
            pending = true
            return false
        }
        lastApplied = now
        pending = false
        return true
    }

    /// The drag ended: whether the pages still need the last frame, which always applies.
    /// The next drag starts afresh.
    public mutating func flush() -> Bool {
        defer { lastApplied = nil; pending = false }
        return pending
    }
}
