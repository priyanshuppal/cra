import Foundation

/// The Library's pages Cra has, in the order of Arc's rail (which also lists Easels and Boosts).
/// Its title, symbol and search prompt are the app's (`LibraryView.swift`).
public enum LibraryPage: String, CaseIterable, Sendable {
    case media, downloads, easels, spaces, boosts, archive
}

/// What a Library page says when its list is empty: nothing saved yet, or nothing matching the
/// search. The words are Arc 1.174's (`strings` on its binary) unless a line says otherwise.
public struct LibraryEmptyState: Equatable, Sendable {
    /// A run of the detail line: words, or the sidebar row's close button drawn inline.
    public enum Part: Equatable, Sendable {
        case text(String)
        /// Arc's archive hint shows the row's ✕ between its words.
        case closeButton
    }

    public var symbol: String
    public var title: String
    /// Nil when there is no detail line.
    public var detail: [Part]?

    public init(symbol: String, title: String, detail: [Part]?) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
    }

    /// The detail as plain text, the ✕ written as "ⓧ" (for tests).
    public var detailText: String? {
        detail?.map { part -> String in
            switch part {
            case .text(let s): s
            case .closeButton: "ⓧ"
            }
        }.joined()
    }

    /// `isEmpty`: the page has nothing at all (otherwise a search or a filter hid everything).
    /// `query`: the search field's text. Nil for Spaces, which has no empty state.
    public static func text(page: LibraryPage, isEmpty: Bool, query: String) -> LibraryEmptyState? {
        let symbol: String
        let title: String
        let detail: [Part]
        switch page {
        case .media:
            symbol = "photo.on.rectangle"
            title = "Nothing here yet!"
            // Arc's line ends "alongside your Captures in Arc."
            detail = [.text("Save media to your Documents, Desktop, and Download Folders to see them here, alongside your Captures in Cra.")]
        case .downloads:
            symbol = "arrow.down.circle"
            title = "Nothing here yet!"
            detail = [.text("Come back after you’ve found some cool stuff to save.")]
        case .easels:
            // Arc's "Out of ideas!" title. Its detail ("Click the + sign in the Sidebar…") points at a
            // menu item Cra's + menu doesn't have, so the line is Cra's.
            symbol = "pencil.and.scribble"
            title = "Out of ideas!"
            detail = [.text("Choose File ▸ New Easel to create a new Easel.")]
        case .boosts:
            symbol = "paintbrush.pointed"
            title = "Nothing Boosted Yet!"
            detail = [.text("Type “New Boost” in the command bar on any site to make your own.")]
        case .archive:
            // HomeButton/ArchiveContentView.swift: "Hover your mouse over a tab and press the " + the
            // row's close button + " to archive it."
            symbol = "archivebox"
            title = "Nothing here yet!"
            detail = [.text("Hover your mouse over a tab and press the "), .closeButton, .text(" to archive it.")]
        case .spaces:
            return nil
        }
        if isEmpty { return LibraryEmptyState(symbol: symbol, title: title, detail: detail) }
        // Arc: "No results found for " ("Empty state subtitle copy for when no search results are
        // found"), the query in curly quotes. A filter alone, with no search, has no detail.
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return LibraryEmptyState(symbol: symbol, title: "No matches",
                                 detail: q.isEmpty ? nil : [.text("No results found for “\(q)”")])
    }
}
