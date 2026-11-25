import Foundation

/// The sidebar's menu on a folder, in Arc's order. Arc 1.174's folder menu, read over
/// Accessibility on an offline copy (21 Nov 2026, docs/arc-parity.md), its strings next to
/// SidebarMenu+ListContextMenu.swift in Arc's binary:
///
///     Share Folder…
///     ──
///     New Nested Folder…, Turn "<name>" into Space, Copy All Links, Copy All Links as Markdown
///     ──
///     Change Icon…, Rename…
///     ──
///     Duplicate, Move to ▸
///     ──
///     Delete
///
/// Cra has no Turn into Space or Duplicate yet. Icon Color ▸ is Cra's (the White and Black folder
/// icon styles) and sits right after Change Icon…. The copy rows are dimmed with no tab in the
/// folder, as the live folder's Copy All Links as Markdown is.
public enum FolderMenu {
    public enum Row: String, CaseIterable, Sendable {
        case share, newNestedFolder, copyAllLinks, copyAllLinksAsMarkdown, changeIcon, iconColor, rename, moveTo, delete
    }

    public static let sections: [[Row]] = [
        [.share],
        [.newNestedFolder, .copyAllLinks, .copyAllLinksAsMarkdown],
        [.changeIcon, .iconColor, .rename],
        [.moveTo],
        [.delete],
    ]

    public static func title(_ row: Row) -> String {
        switch row {
        case .share: "Share Folder…"
        case .newNestedFolder: "New Nested Folder…"
        case .copyAllLinks: "Copy All Links"
        case .copyAllLinksAsMarkdown: "Copy All Links as Markdown"
        case .changeIcon: "Change Icon…"
        case .iconColor: "Icon Color"
        case .rename: "Rename…"
        case .moveTo: "Move to"
        case .delete: "Delete"
        }
    }

    /// `tabs`: the tabs anywhere inside the folder, nested folders and splits included.
    /// `shareable`: whether Share Folder… has a link to copy (`FolderShareLink`).
    public static func isEnabled(_ row: Row, tabs: Int, shareable: Bool) -> Bool {
        switch row {
        case .share: shareable
        case .copyAllLinks, .copyAllLinksAsMarkdown: tabs > 0
        default: true
        }
    }

    /// Copy All Links: every tab's address without trackers, one per line, as ⇧⌘C copies picked tabs.
    public static func links(_ urls: [String]) -> String { CleanURL.links(urls) }

    /// Copy All Links as Markdown: a Markdown list, one `- [title](address)` per tab, the address
    /// without trackers as Copy URL as Markdown copies it.
    public static func markdown(_ tabs: [(title: String, url: String)]) -> String {
        tabs.map { "- [\($0.title)](\(CleanURL.withoutTrackers($0.url)))" }.joined(separator: "\n")
    }
}
