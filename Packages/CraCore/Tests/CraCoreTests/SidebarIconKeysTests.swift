import CraCore
import Foundation
import Testing

/// A tab on `url` whose home is `saved` (its own URL when nil).
private func tab(_ url: String, saved: String? = nil, favicon: String? = nil, custom: String? = nil) -> TabData {
    var t = TabData(url: saved ?? url)
    t.url = url
    if let favicon { t.faviconKey = favicon }
    t.customIconKey = custom
    return t
}

/// The icon keys a sidebar row watches must be the ones its model shows: a key the model reads that
/// the list doesn't watch leaves the row on the old icon (or none) when the page reports a new one.
struct SidebarIconKeysTests {
    private static func item(_ data: ItemData) -> SidebarItem {
        SidebarItem(id: UUID(), parentID: nil, title: nil, children: [], isUnread: false, createdAt: Date(timeIntervalSince1970: 0), data: data)
    }

    @Test(arguments: [
        // A Today tab: its own icon only.
        ("today", tab("https://github.com/a", favicon: "github.com#1"), false, nil, ["github.com#1"]),
        // A tab that never loaded: the host its key starts as.
        ("unloaded", tab("https://example.org/"), false, nil, ["example.org"]),
        // No icon key at all (a page with no host): nothing.
        ("no key", tab("about:blank"), false, nil, []),
        // A Today tab's saved URL is not a home it shows.
        ("today elsewhere", tab("https://b.com/", saved: "https://a.com/", favicon: "b.com"), false, nil, ["b.com"]),
        // Pinned: its own icon and its home's site, also while on its saved page.
        ("pinned home", tab("https://a.com/x", favicon: "a.com#2"), true, nil, ["a.com#2", "a.com"]),
        ("pinned away", tab("https://b.com/", saved: "https://a.com/", favicon: "b.com#3"), true, nil, ["b.com#3", "a.com"]),
        // A picked icon is both its own icon and its home's.
        ("pinned custom", tab("https://b.com/", saved: "https://a.com/", favicon: "b.com", custom: "custom-1"), true, nil,
         ["custom-1", "custom-1"]),
        // A pinned tab whose home has no host (notes): no home key.
        ("pinned no home", tab("https://b.com/", saved: "notes", favicon: "b.com"), true, nil, ["b.com"]),
        // A peek open from the tab: its badge's icon, last.
        ("peek", tab("https://a.com/", favicon: "a.com"), false, "c.com#4", ["a.com", "c.com#4"]),
        ("pinned peek", tab("https://b.com/", saved: "https://a.com/", favicon: "b.com"), true, "c.com",
         ["b.com", "a.com", "c.com"]),
    ] as [(String, TabData, Bool, String?, [String])])
    func tabRow(_ name: String, tab: TabData, pinned: Bool, peek: String?, keys: [String]) {
        #expect(SidebarIconKeys.tabRow(tab, pinned: pinned, peekBadge: peek) == keys, "\(name)")
    }

    @Test func homeIsThePickedIconElseTheSavedSite() {
        #expect(SidebarIconKeys.home(tab("https://b.com/", saved: "https://A.com/p")) == "a.com")
        #expect(SidebarIconKeys.home(tab("https://b.com/", saved: "https://a.com/", custom: "mine")) == "mine")
        #expect(SidebarIconKeys.home(tab("https://b.com/", saved: "")) == nil)
    }

    /// A split's cells show each tab pane's own icon, in pane order; a pane that isn't a tab shows none.
    @Test func splitRowWatchesEachPane() {
        let left = Self.item(.tab(tab("https://a.com/", favicon: "a.com#1")))
        let right = Self.item(.tab(tab("https://b.com/", saved: "https://z.com/", favicon: "b.com", custom: "pick")))
        let blank = Self.item(.tab(tab("about:blank")))
        let folder = Self.item(.folder)
        #expect(SidebarIconKeys.splitRow(panes: [left, right]) == ["a.com#1", "pick"])
        #expect(SidebarIconKeys.splitRow(panes: [right, left]) == ["pick", "a.com#1"])
        #expect(SidebarIconKeys.splitRow(panes: [left, blank, folder]) == ["a.com#1"])
        #expect(SidebarIconKeys.splitRow(panes: []) == [])
    }
}
