import Foundation

/// How evenly an animation's frames were drawn: one `record` per display-link tick. A gap of two intervals is one
/// frame missed, a gap of three is two missed, and so on, so "at 120 Hz, 2 missed" reads off what the screen showed
/// rather than how often a timer looked.
public struct FramePacing: Sendable, Equatable {
    public private(set) var frames = 0
    public private(set) var missed = 0
    /// The longest time between two frames, in seconds.
    public private(set) var longestGap: TimeInterval = 0
    private var interval: TimeInterval = 0
    private var last: TimeInterval?

    public init() {}

    /// A frame shown at `timestamp` (a display link's target timestamp), on a display refreshing every `interval`.
    public mutating func record(timestamp: TimeInterval, interval: TimeInterval) {
        frames += 1
        if interval > 0 { self.interval = interval }
        if let last {
            let gap = timestamp - last
            longestGap = max(longestGap, gap)
            if self.interval > 0 { missed += max(0, Int((gap / self.interval).rounded()) - 1) }
        }
        last = timestamp
    }

    /// The display's refresh rate, from the last interval seen.
    public var hz: Int { interval > 0 ? Int((1 / interval).rounded()) : 0 }
    public var longestGapMs: Int { Int((longestGap * 1000).rounded()) }
}
