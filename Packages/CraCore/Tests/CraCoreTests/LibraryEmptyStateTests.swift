import CraCore
import Testing

/// What each Library page says when its list is empty, in Arc 1.174's words.
struct LibraryEmptyStateTests {
    struct Row: Sendable, CustomTestStringConvertible {
        let page: LibraryPage
        let symbol: String
        let title: String
        let detail: String
        var testDescription: String { page.rawValue }
    }

    static let empty: [Row] = [
        Row(page: .media, symbol: "photo.on.rectangle", title: "Nothing here yet!",
            detail: "Save media to your Documents, Desktop, and Download Folders to see them here, alongside your Captures in Cra."),
        Row(page: .downloads, symbol: "arrow.down.circle", title: "Nothing here yet!",
            detail: "Come back after you’ve found some cool stuff to save."),
        Row(page: .easels, symbol: "pencil.and.scribble", title: "Out of ideas!",
            detail: "Choose File ▸ New Easel to create a new Easel."),
        Row(page: .boosts, symbol: "paintbrush.pointed", title: "Nothing Boosted Yet!",
            detail: "Type “New Boost” in the command bar on any site to make your own."),
        Row(page: .archive, symbol: "archivebox", title: "Nothing here yet!",
            detail: "Hover your mouse over a tab and press the ⓧ to archive it."),
    ]

    @Test(arguments: empty) func nothingSavedYet(_ row: Row) throws {
        let s = try #require(LibraryEmptyState.text(page: row.page, isEmpty: true, query: ""))
        #expect(s.symbol == row.symbol)
        #expect(s.title == row.title)
        #expect(s.detailText == row.detail)
    }

    @Test(arguments: empty) func emptyPageIgnoresTheSearch(_ row: Row) throws {
        let s = try #require(LibraryEmptyState.text(page: row.page, isEmpty: true, query: "github"))
        #expect(s.title == row.title)
        #expect(s.detailText == row.detail)
    }

    @Test(arguments: empty) func noHitsNamesTheQuery(_ row: Row) throws {
        let s = try #require(LibraryEmptyState.text(page: row.page, isEmpty: false, query: "github"))
        #expect(s.symbol == row.symbol)
        #expect(s.title == "No matches")
        #expect(s.detailText == "No results found for “github”")
    }

    @Test func queryIsTrimmedAndKeepsItsCase() throws {
        let s = try #require(LibraryEmptyState.text(page: .downloads, isEmpty: false, query: "  Cra Release \n"))
        #expect(s.detailText == "No results found for “Cra Release”")
    }

    @Test func queryWithCurlyQuotesIsShownAsTyped() throws {
        let s = try #require(LibraryEmptyState.text(page: .archive, isEmpty: false, query: "“quoted” ’s"))
        #expect(s.detailText == "No results found for ““quoted” ’s”")
    }

    @Test(arguments: empty) func filterAloneHasNoDetail(_ row: Row) throws {
        // Archive and Downloads can hide everything with a filter chip and no search.
        let s = try #require(LibraryEmptyState.text(page: row.page, isEmpty: false, query: "   "))
        #expect(s.title == "No matches")
        #expect(s.detail == nil)
    }

    @Test func archiveHintCarriesTheCloseButtonBetweenItsWords() throws {
        let s = try #require(LibraryEmptyState.text(page: .archive, isEmpty: true, query: ""))
        #expect(s.detail == [.text("Hover your mouse over a tab and press the "), .closeButton, .text(" to archive it.")])
    }

    @Test func onlyTheArchiveDrawsTheCloseButton() {
        for page in LibraryPage.allCases where page != .archive {
            let parts = LibraryEmptyState.text(page: page, isEmpty: true, query: "")?.detail ?? []
            #expect(!parts.contains(.closeButton), "\(page)")
        }
    }

    @Test func spacesHasNoEmptyState() {
        #expect(LibraryEmptyState.text(page: .spaces, isEmpty: true, query: "") == nil)
        #expect(LibraryEmptyState.text(page: .spaces, isEmpty: false, query: "x") == nil)
    }
}
