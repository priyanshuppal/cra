import Foundation

/// Arc's toast after sidebar items close as one step it can undo (CloseItemsCompletionToast, from
/// SharedWindowsFeature/WindowsCloseContentAction): what went, then "! Use", the ⌘Z keys in a cap and "to undo."
/// (Toasts/ToastController's undo shortcut copy). Arc 1.174.3's English, decoded from its binary
/// (docs/arc-reverse-engineering.md, "Undo in the sidebar").
public enum CloseItemsToast {
    public enum Kind: Equatable, Sendable {
        /// Clear on Today: "Title for toast that confirms tabs were cleared".
        case clear
        /// Delete Folder: "Confirmation toast when a sidebar far was been deleted" / "…multiple sidebar folders are deleted".
        case deleteFolder
    }

    /// "Copy for Command Z keys in undo shortcut".
    public static let undoKeys = "⌘Z"

    /// The toast's text and its key cap: the text before the cap, the keys, the text after.
    public static func text(kind: Kind, count: Int) -> (text: String, keyCap: (keys: String, after: String)?) {
        let title: String
        switch kind {
        case .clear: title = "Cleared Tabs"
        case .deleteFolder: title = count == 1 ? "Folder deleted" : "Folders deleted"
        }
        return (title + "! Use", (undoKeys, "to undo."))
    }
}
