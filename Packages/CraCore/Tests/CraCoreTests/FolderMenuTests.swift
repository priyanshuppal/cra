import CraCore
import Testing

/// The folder's menu in Arc 1.174's order, with Copy All Links and its Markdown twin.
struct FolderMenuTests {
    /// Arc's groups (AX read, 21 Nov 2026): Share Folder… ─ New Nested Folder…, Copy All Links,
    /// Copy All Links as Markdown ─ Change Icon…, Rename… ─ Move to ─ Delete. Icon Color ▸ is Cra's,
    /// after Change Icon….
    @Test func rowsInArcsOrder() {
        let titles = FolderMenu.sections.map { $0.map(FolderMenu.title) }
        #expect(titles == [
            ["Share Folder…"],
            ["New Nested Folder…", "Copy All Links", "Copy All Links as Markdown"],
            ["Change Icon…", "Icon Color", "Rename…"],
            ["Move to"],
            ["Delete"],
        ])
        #expect(Set(FolderMenu.sections.flatMap { $0 }) == Set(FolderMenu.Row.allCases))
    }

    /// An empty folder has nothing to copy; everything else stays on. Share Folder… follows its link.
    @Test(arguments: [(0, false), (1, true), (5, true)])
    func copyRowsNeedATab(tabs: Int, on: Bool) {
        #expect(FolderMenu.isEnabled(.copyAllLinks, tabs: tabs, shareable: true) == on)
        #expect(FolderMenu.isEnabled(.copyAllLinksAsMarkdown, tabs: tabs, shareable: true) == on)
        for row in FolderMenu.Row.allCases where ![.copyAllLinks, .copyAllLinksAsMarkdown, .share].contains(row) {
            #expect(FolderMenu.isEnabled(row, tabs: tabs, shareable: false))
        }
        #expect(FolderMenu.isEnabled(.share, tabs: tabs, shareable: true))
        #expect(!FolderMenu.isEnabled(.share, tabs: tabs, shareable: false))
    }

    /// One address per line, trackers stripped, anything else left as it is.
    @Test func linksAreCleanOnePerLine() {
        let urls = ["https://a.com/x?utm_source=news&id=3", "https://b.com/?fbclid=zz#top", "file:///tmp/n.txt"]
        #expect(FolderMenu.links(urls) == "https://a.com/x?id=3\nhttps://b.com/#top\nfile:///tmp/n.txt")
        #expect(FolderMenu.links([]) == "")
    }

    @Test func markdownListsEachTab() {
        let md = FolderMenu.markdown([("Article", "https://a.com/x?utm_medium=mail"), ("PR #12", "https://github.com/o/r/pull/12")])
        #expect(md == "- [Article](https://a.com/x)\n- [PR #12](https://github.com/o/r/pull/12)")
        #expect(FolderMenu.markdown([]) == "")
    }
}
