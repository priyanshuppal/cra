import Foundation

/// What one browser window's refresh (MainWindowController.refresh: its panes, pages, toolbar,
/// sidebar width and visibility) reads from windows.json and the sidebar's revision. The window
/// observed all of `WindowPrefs`, so a tab picked in one window, a window moved or a folder opened
/// re-ran every window's refresh, about 8 ms each. It refreshes when this key changes instead.
public struct WindowRefreshKey: Equatable {
    /// This window's session without what refresh never reads: its frame and full-screen flag
    /// are saved as the window moves, and AppKit already shows them.
    public let session: WindowSession?
    public let sidebarWidth: Double
    /// This window's panes that another window shows too. They decide which window holds the
    /// page and which shows a snapshot of it (showsElsewhere), so another window's pick matters
    /// here only when it starts or stops showing one of them.
    public let sharedPanes: Set<UUID>
    /// SidebarStore.revision: tree edits (a tab opened, closed or moved, a split made). A plain
    /// pick doesn't move it; its change reaches the window through `session`.
    public let revision: Int

    /// `panes` gives the tabs a window shows (SidebarStore.visiblePaneTabIDs of its focused space).
    public init(window id: UUID, prefs: WindowPrefs, revision: Int, panes: (WindowSession) -> [UUID]) {
        let own = prefs.windows.first { $0.id == id }
        session = own.map {
            var s = $0
            s.frame = nil
            s.fullScreen = false
            return s
        }
        sidebarWidth = prefs.sidebarWidth
        let mine = Set(own.map(panes) ?? [])
        sharedPanes = mine.isEmpty ? [] : mine.intersection(prefs.windows.filter { $0.id != id }.flatMap(panes))
        self.revision = revision
    }
}
