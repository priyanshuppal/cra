import Foundation

/// The favicon keys a sidebar row's model shows. A list's build observes these key by key, so a page
/// reporting its icon rebuilds only the lists that show it, and reads them ahead of the rows
/// (FaviconCache.prefetch). The models are built later, outside the build's observation (#618), so a
/// key the model reads and this leaves out would never rebuild the row. Each key also falls back to
/// its site's (FaviconKey.siteKey), which the cache observes with it.
public enum SidebarIconKeys {
    /// A pinned tab's home icon: the one picked for it, else its saved page's site's. Its row shows it
    /// next to the page's own once the tab has left its saved page.
    public static func home(_ tab: TabData) -> String? {
        tab.customIconKey ?? FaviconKey.key(for: tab.savedURL)
    }

    /// A tab's row: its own icon, a pinned tab's home icon (watched before it navigates away, so the row
    /// that starts showing it already has it), and the icon of the peek it has open.
    public static func tabRow(_ tab: TabData, pinned: Bool, peekBadge: String?) -> [String] {
        [tab.iconKey, pinned ? home(tab) : nil, peekBadge].compactMap { $0 }
    }

    /// A split's row: each tab pane's own icon, in pane order. Its cells show no home or peek icon.
    public static func splitRow(panes: [SidebarItem]) -> [String] {
        panes.compactMap { $0.tab?.iconKey }
    }
}
