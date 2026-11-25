/// The pane that takes focus when the focused pane of a split closes and the split stays: its
/// neighbour, the pane that slides into its slot, or the one before it when it was the last.
/// Before this the first pane always took focus, however far from the closed one it was.
public enum SplitClose {
    /// `closingIndex` is the closed pane's place before it closed, `remaining` how many panes are
    /// left; nil when none are.
    public static func successor(closingIndex: Int, remaining: Int) -> Int? {
        guard remaining > 0 else { return nil }
        return min(max(0, closingIndex), remaining - 1)
    }
}
