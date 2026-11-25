import CraCore
import Testing

/// Window ▸ Open Library… and View Downloads… read Close Library and Hide Downloads while their
/// Library is open, as in Arc 1.174.3.
struct MenuBarTitlesTests {
    @Test(arguments: [
        (String?.none, "Open Library…", "View Downloads…"),
        ("downloads", "Close Library", "Hide Downloads"),
        // Another page: the Library closes, but View Downloads… goes to Downloads.
        ("media", "Close Library", "View Downloads…"),
        ("archive", "Close Library", "View Downloads…"),
    ])
    func libraryRowsFlipWithTheirPage(open: String?, library: String, downloads: String) {
        #expect(MenuBarTitles.library(row: .openLibrary, openPage: open, downloads: "downloads") == library)
        #expect(MenuBarTitles.library(row: .viewDownloads, openPage: open, downloads: "downloads") == downloads)
    }

    /// The title says Close or Hide exactly when the row's shortcut closes the Library.
    @Test func titleMatchesWhatTheRowDoes() {
        for open in [nil, "downloads", "media", "easels", "boosts", "archive"] as [String?] {
            for row in MenuBarTitles.LibraryRow.allCases {
                let title = MenuBarTitles.library(row: row, openPage: open, downloads: "downloads")
                let closes = LibraryShortcut.step(requested: row == .viewDownloads ? "downloads" : nil, shown: open) == .close
                #expect(closes == !title.hasSuffix("…"), "\(row) on \(open ?? "closed"): \(title)")
            }
        }
    }
}
