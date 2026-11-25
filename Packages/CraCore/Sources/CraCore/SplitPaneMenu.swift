import Foundation

/// A split pane's Split View menu, the pane toolbar's (Arc's `SplitViewPaneMenuOperation`, each
/// `.enabled|.disabled`). Arc 1.172.2 read live over AX: Move Left, Move Right, Add Right Split, Add Left
/// Split, Separate Tab from Split, Convert to Vertical Split View, Share Split View…. A stacked split
/// says Up/Down and Bottom/Top. Moves are greyed out at the ends and Add at the pane limit. Copy Link
/// (in Arc's enum) and Close this Split Pane (Cra's since before) follow, each after a separator.
public enum SplitPaneMenu {
    public enum Operation: String, Equatable, Sendable {
        case moveLeft, moveRight, addPaneRight, addPaneLeft, addPaneBottom, addPaneTop
        case separate, flipLayoutOrientation, share, copyLink, close

        /// The menu's title for this row in a split laid out `orientation`.
        public func title(_ orientation: SplitOrientation) -> String {
            let stacked = orientation == .vertical
            switch self {
            case .moveLeft: return stacked ? "Move Up" : "Move Left"
            case .moveRight: return stacked ? "Move Down" : "Move Right"
            case .addPaneRight: return "Add Right Split"
            case .addPaneLeft: return "Add Left Split"
            case .addPaneBottom: return "Add Bottom Split"
            case .addPaneTop: return "Add Top Split"
            case .separate: return "Separate Tab from Split"
            case .flipLayoutOrientation: return stacked ? "Convert to Horizontal Split View" : "Convert to Vertical Split View"
            case .share: return "Share Split View…"
            case .copyLink: return "Copy Link"
            case .close: return "Close this Split Pane"
            }
        }

        /// Whether a new pane goes after this one (right or below); nil for a row that adds none.
        public var addsAfter: Bool? {
            switch self {
            case .addPaneRight, .addPaneBottom: return true
            case .addPaneLeft, .addPaneTop: return false
            default: return nil
            }
        }

        /// A separator goes above this row.
        public var startsGroup: Bool { self == .copyLink || self == .close }
    }

    public struct Row: Equatable, Sendable {
        public let op: Operation
        public let enabled: Bool
        public init(_ op: Operation, _ enabled: Bool) { self.op = op; self.enabled = enabled }
    }

    /// The menu of the pane at `index` of `count` panes, laid out `orientation`, in a split that holds
    /// at most `limit` panes (`SplitPaneLimit.maximum`).
    public static func rows(index: Int, count: Int, orientation: SplitOrientation, limit: Int) -> [Row] {
        let canAdd = count < limit
        let stacked = orientation == .vertical
        return [
            Row(.moveLeft, index > 0),
            Row(.moveRight, index < count - 1),
            Row(stacked ? .addPaneBottom : .addPaneRight, canAdd),
            Row(stacked ? .addPaneTop : .addPaneLeft, canAdd),
            Row(.separate, true),
            Row(.flipLayoutOrientation, true),
            Row(.share, true),
            Row(.copyLink, true),
            Row(.close, true),
        ]
    }

    /// The index `SidebarStore.moveWithinSplit` takes to move the pane at `index` one place
    /// (`.moveLeft` or `.moveRight`): it counts the slot before the pane leaves.
    public static func moveTarget(_ op: Operation, from index: Int) -> Int? {
        switch op {
        case .moveLeft: return index - 1
        case .moveRight: return index + 2
        default: return nil
        }
    }
}
