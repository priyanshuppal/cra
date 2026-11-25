import Foundation

/// ⌘Z's steps in the sidebar, newest last (Arc's ArcUndoManager, SharedWindowFeature/Undo/WindowReducer+Undo):
/// a drop in the wrong place, a deleted folder or a Clear comes back with one press, and so do a Tidy and a
/// closed tab, in the order they happened. Kept in memory only, as Arc's was.
public struct SidebarUndo {
    /// The containers an edit could change, as they were before it, parents first. Whole items, so a folder
    /// or split that went comes back with its name, icon and panes' layout.
    public struct Snapshot: Equatable {
        public var containers: [SidebarItem]
        public init(containers: [SidebarItem]) { self.containers = containers }
    }

    public enum Kind: Equatable {
        /// Moves, a new folder, a removed header: put the containers back as they were. `created` are the
        /// containers the edit made, which go again once they are empty.
        case tree(Snapshot, created: [UUID])
        /// Clear, Archive Tabs Above/Below, Delete Folder: these tabs come back from the archive, then the
        /// containers are put back as they were.
        case archived([UUID], Snapshot)
        /// A Tidy run (its own undo, `SidebarStore.undoTidy`).
        case tidy(spaceID: UUID, todayBefore: [UUID], moved: [UUID])
        /// The spaces' order before a space moved.
        case spaceOrder([UUID])
        /// A tab, pinned tab or Peek closed on its own: ⇧⌘T's rules bring it back (ReopenClosedTab).
        case reopen
    }

    public struct Entry: Equatable {
        public var label: String
        public var kind: Kind
        public init(_ label: String, _ kind: Kind) {
            self.label = label
            self.kind = kind
        }
    }

    public private(set) var entries: [Entry] = []
    /// How many steps are kept.
    public static let limit = 100

    public init() {}

    public mutating func record(_ entry: Entry) {
        entries.append(entry)
        if entries.count > Self.limit { entries.removeFirst(entries.count - Self.limit) }
    }

    /// The newest step, off the stack.
    public mutating func pop() -> Entry? { entries.popLast() }

    /// What Edit ▸ Undo names: the newest step's label.
    public var label: String? { entries.last?.label }

    /// The newest step when it is a Tidy.
    public var newestTidy: (spaceID: UUID, todayBefore: [UUID], moved: [UUID])? {
        guard case .tidy(let sid, let before, let moved)? = entries.last?.kind else { return nil }
        return (sid, before, moved)
    }

    /// A Tidy run that moved nothing takes ⌘Z off the run before it, as Cra's single Tidy undo did.
    public mutating func dropNewestTidy() {
        if newestTidy != nil { entries.removeLast() }
    }

    // MARK: Labels

    /// Arc 1.174.3's titles (Edit ▸ "Undo <label>"), read from its binary, where they sit inline beside their
    /// comments: "Undo prompt for moving a single item" / "…multiple items" (WindowData+TopBar).
    public static func move(count: Int) -> String { count == 1 ? "Move Item" : "Move Items" }
    /// "Undo prompt for undoing clearing a single tab" / "…multiple tabs" (WindowData+CloseItems): every close
    /// of several sidebar items at once (Clear, Archive Tabs Above, Below and Other Tabs).
    public static func clear(count: Int) -> String { count == 1 ? "Clear Tab" : "Clear Tabs" }
    /// "Undo creating a new folder" (WindowData+Folders).
    public static let newFolder = "New Folder…"
    /// "Undo moving a space" (WindowData+Spaces).
    public static let moveSpace = "Move Space"
    /// "Undo prompt for removing tab group header" and, beside it, Tidy's.
    public static let removeHeader = "Remove Header"
    public static let tidy = "Tidy Tabs"
    /// Cra's: Arc's titles for these weren't found in its binary.
    public static let deleteFolder = "Delete Folder"
    public static let closeTab = "Close Tab"
    public static let closePeek = "Close Peek"

    // MARK: Putting a snapshot back

    /// The items to write so the snapshot's containers hold what they held, given the sidebar `items` now.
    /// A container that went comes back (empty, then filled) when its parent is in the snapshot and still
    /// there. An item still in the sidebar goes back under its container unless that would put a container
    /// inside itself. What was added since stays, at the index it has now. Items that are gone are skipped.
    public static func restore(_ snapshot: Snapshot, in items: [UUID: SidebarItem]) -> [UUID: SidebarItem] {
        var out: [UUID: SidebarItem] = [:]
        func get(_ id: UUID) -> SidebarItem? { out[id] ?? items[id] }
        let saved = Set(snapshot.containers.map(\.id))
        for c in snapshot.containers where get(c.id) == nil {
            guard let p = c.parentID, saved.contains(p), get(p) != nil else { continue }
            var back = c
            back.children = []
            out[c.id] = back
        }
        func isWithin(_ container: UUID, _ id: UUID) -> Bool {
            var cur: UUID? = container
            var hops = 0
            while let c = cur, hops < 64 {
                if c == id { return true }
                cur = get(c)?.parentID
                hops += 1
            }
            return false
        }
        for c in snapshot.containers where get(c.id) != nil {
            for k in c.children {
                guard var item = get(k), item.parentID != c.id, !isWithin(c.id, k) else { continue }
                if let old = item.parentID, var from = get(old) {
                    from.children.removeAll { $0 == k }
                    out[old] = from
                }
                item.parentID = c.id
                out[k] = item
            }
        }
        for c in snapshot.containers {
            guard var now = get(c.id) else { continue }
            let children = order(saved: c.children.filter { get($0)?.parentID == c.id },
                                 current: now.children.filter { get($0)?.parentID == c.id })
            if children != now.children {
                now.children = children
                out[c.id] = now
            }
        }
        return out
    }

    /// `saved` in its order, with each of `current`'s others back at the index it has in `current`.
    public static func order(saved: [UUID], current: [UUID]) -> [UUID] {
        let kept = Set(saved)
        var result = saved
        for (i, id) in current.enumerated() where !kept.contains(id) {
            result.insert(id, at: min(i, result.count))
        }
        return result
    }
}
