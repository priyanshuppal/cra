import Foundation

/// A tab dragged over another tab's middle offers to combine into a split only once it has stayed
/// on that row a moment, so a tab dragged down the list to reorder it doesn't open the split
/// preview (and tick) on every row it crosses.
///
/// Arc 1.174.3 waits the same way: its sidebar shows `SplitDragPreviewView` only after
/// `_splitDropTargetDelaySatisfied` (fields `_splitDropTargetDelaySatisfied`, `_splitPreviewView`,
/// flag `sidebar-drag-to-split-preview-ui-enabled`; docs/arc-reverse-engineering.md "Drag and drop").
public struct SidebarSplitDwell {
    /// [U] Arc's value not measured: its binary names the delay but its length wasn't timed.
    public static let delay: TimeInterval = 0.3

    /// The row the pointer is over the middle of, and when it got there.
    public private(set) var row: UUID?
    public private(set) var since: TimeInterval?

    public init() {}

    /// One drag sample: `row` is the tab whose middle the pointer is over (nil when it is over
    /// anything else). True once it has stayed on that same row for `delay`; another row, or
    /// none, starts the wait over.
    public mutating func sample(row: UUID?, at now: TimeInterval) -> Bool {
        guard let row else { reset(); return false }
        if row != self.row || since == nil {
            self.row = row
            since = now
        }
        return now - (since ?? now) >= Self.delay
    }

    public mutating func reset() {
        row = nil
        since = nil
    }
}
