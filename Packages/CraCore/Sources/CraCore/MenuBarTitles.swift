import Foundation

/// Menu bar rows that say what they will do, as Arc's do. Arc 1.174.3 retitles its Window menu's
/// Library rows while their page is open; the short titles are Swift small strings, decoded from the
/// mov/movk immediates beside their comments in `otool -tV`/`llvm-objdump -d` of Arc's arm64 slice
/// (26 Nov 2026): "Open Library…" ("Menu item title to open the Library.") and "Close Library"
/// ("…to close the Library."); "View Downloads…" ("MenuItem title to open the downloads pane", the
/// only Downloads title in the binary with or without the ellipsis) and "Hide Downloads" ("MenuItem
/// title to lock close the downloads pane").
public enum MenuBarTitles {
    public enum LibraryRow: CaseIterable, Sendable {
        /// Window ▸ Open Library… (⇧⌘L)
        case openLibrary
        /// Window ▸ View Downloads… (⇧⌘J)
        case viewDownloads
    }

    /// The row's title with the main window's Library on `openPage` (nil while it's closed). It flips
    /// exactly when choosing the row would close the Library (`LibraryShortcut`), so the title never
    /// says Close while the row opens: View Downloads… on another page goes to Downloads.
    public static func library<Page: Equatable>(row: LibraryRow, openPage: Page?, downloads: Page) -> String {
        let closes = LibraryShortcut.step(requested: row == .viewDownloads ? downloads : nil, shown: openPage) == .close
        return switch row {
        case .openLibrary: closes ? "Close Library" : "Open Library…"
        case .viewDownloads: closes ? "Hide Downloads" : "View Downloads…"
        }
    }
}
