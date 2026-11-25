import Foundation
import Testing
@testable import CraCore

/// A window refreshes when its own key changes, not on every write to windows.json: a pick in one
/// window re-ran every window's refresh, about 8 ms each (docs/speed.md).
@Suite struct WindowRefreshKeyTests {
    let space = UUID(), other = UUID()
    let a = UUID(), b = UUID()
    let tab1 = UUID(), tab2 = UUID(), tab3 = UUID(), tab4 = UUID()

    /// Window A shows tab1, window B tab3, both on `space`.
    var prefs: WindowPrefs {
        WindowPrefs(windows: [
            WindowSession(id: a, focusedSpaceID: space, selectedTabPerSpace: [space: tab1], frame: "{{0, 0}, {800, 600}}"),
            WindowSession(id: b, focusedSpaceID: space, selectedTabPerSpace: [space: tab3]),
        ])
    }

    /// A window's panes: its focused space's open tab, as SidebarStore.visiblePaneTabIDs for a tab outside a split.
    static func panes(_ w: WindowSession) -> [UUID] {
        w.focusedSpaceID.flatMap { w.selectedTabPerSpace[$0] }.map { [$0] } ?? []
    }

    func key(_ p: WindowPrefs, revision: Int = 0, makingSpace: Bool = false) -> WindowRefreshKey {
        WindowRefreshKey(window: a, prefs: p, revision: revision, makingSpace: makingSpace, panes: Self.panes)
    }

    func session(_ p: inout WindowPrefs, _ id: UUID, _ change: (inout WindowSession) -> Void) {
        change(&p.windows[p.windows.firstIndex { $0.id == id }!])
    }

    @Test(arguments: [
        "another window's pick", "another window's space", "a window-frame save", "full screen",
        "a folder expanded", "a folder peeked", "pinned collapsed", "favorites card dismissed", "new windows' sidebar",
    ])
    func leavesThisWindowAlone(_ change: String) {
        var p = prefs
        let folder = UUID()
        switch change {
        case "another window's pick": session(&p, b) { $0.selectedTabPerSpace[space] = tab4 }
        case "another window's space": session(&p, b) { $0.focusedSpaceID = other; $0.selectedTabPerSpace[other] = tab4 }
        case "a window-frame save": session(&p, a) { $0.frame = "{{40, 40}, {900, 700}}" }
        case "full screen": session(&p, a) { $0.fullScreen = true }
        case "a folder expanded": p.expandedFolders.insert(folder)
        case "a folder peeked": p.peekedFolders[folder] = [tab1]
        case "pinned collapsed": p.collapsedPinnedSpaces.insert(space)
        case "favorites card dismissed": p.favoritesEmptyStateDismissed.insert(UUID())
        default: p.sidebarVisibleInNewWindows = false
        }
        #expect(key(p) == key(prefs), "\(change) must not refresh window A")
    }

    @Test(arguments: ["its own pick", "a space switch", "the sidebar width", "its sidebar hidden", "a tree edit",
                      "another window showing its tab"])
    func changesThisWindow(_ change: String) {
        var p = prefs
        var revision = 0
        switch change {
        case "its own pick": session(&p, a) { $0.selectedTabPerSpace[space] = tab2 }
        case "a space switch": session(&p, a) { $0.focusedSpaceID = other }
        case "the sidebar width": p.sidebarWidth = 400
        case "its sidebar hidden": session(&p, a) { $0.sidebarVisible = false }
        case "a tree edit": revision = 1
        // Which of the two holds the page, and which shows its snapshot, is decided again (showsElsewhere).
        default: session(&p, b) { $0.selectedTabPerSpace[space] = tab1 }
        }
        #expect(key(p, revision: revision) != key(prefs), "\(change) must refresh window A")
    }

    /// Opening Create a Space, and leaving it, refreshes the window though its session and the spaces
    /// may read the same: the new space can preview the theme its space already has (1 in 9), and the
    /// old space's page stayed up.
    @Test func makingSpaceInAndOut() {
        let before = key(prefs), making = key(prefs, makingSpace: true), after = key(prefs)
        #expect(making != before, "opening Create a Space must refresh window A")
        #expect(after != making, "and so must leaving it")
        #expect(after == before, "with nothing else changed, leaving is the flag alone")
    }

    /// Another window leaving a tab this window shows refreshes this one too: it may hold the page now.
    @Test func anotherWindowLeavingItsTab() {
        var shared = prefs
        session(&shared, b) { $0.selectedTabPerSpace[space] = tab1 }
        var left = shared
        session(&left, b) { $0.selectedTabPerSpace[space] = tab4 }
        #expect(key(shared).sharedPanes == [tab1])
        #expect(key(left).sharedPanes.isEmpty)
        #expect(key(left) != key(shared))
    }

    /// A window that is gone (closed while a change was on its way) has no session, and nothing it shares.
    @Test func windowGone() {
        let k = WindowRefreshKey(window: UUID(), prefs: prefs, revision: 0, makingSpace: false, panes: Self.panes)
        #expect(k.session == nil)
        #expect(k.sharedPanes.isEmpty)
    }
}
