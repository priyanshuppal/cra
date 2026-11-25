import CraCore
import Foundation
import Testing

struct SidebarUndoTests {
    /// A space's Pinned and Today, edited as the store edits them.
    private struct Tree {
        var items: [UUID: SidebarItem] = [:]
        let today: UUID
        let pinned: UUID

        init() {
            let space = UUID()
            let t = SidebarItem.container(.today(spaceID: space))
            let p = SidebarItem.container(.pinned(spaceID: space))
            today = t.id
            pinned = p.id
            items[t.id] = t
            items[p.id] = p
        }

        @discardableResult
        mutating func add(_ item: SidebarItem) -> UUID {
            items[item.id] = item
            items[item.parentID!]!.children.append(item.id)
            return item.id
        }

        mutating func tab(_ name: String, in parent: UUID) -> UUID { add(.tab("https://example.com/\(name)", parent: parent)) }

        mutating func move(_ id: UUID, to parent: UUID, at index: Int) {
            if let old = items[id]?.parentID { items[old]?.children.removeAll { $0 == id } }
            items[id]?.parentID = parent
            items[parent]!.children.insert(id, at: min(index, items[parent]!.children.count))
        }

        /// Gone, as a closed tab or deleted folder is (its own children with it).
        mutating func remove(_ id: UUID) {
            for c in items[id]?.children ?? [] { remove(c) }
            if let p = items[id]?.parentID { items[p]?.children.removeAll { $0 == id } }
            items[id] = nil
        }

        /// The containers as the store snapshots them: each section with the folders and splits in it.
        func snapshot() -> SidebarUndo.Snapshot {
            var out: [SidebarItem] = []
            func add(_ id: UUID) {
                guard let it = items[id], !it.isTab else { return }
                out.append(it)
                it.children.forEach(add)
            }
            add(pinned)
            add(today)
            return .init(containers: out)
        }

        mutating func restore(_ snapshot: SidebarUndo.Snapshot) {
            items.merge(SidebarUndo.restore(snapshot, in: items)) { $1 }
        }

        func children(_ id: UUID) -> [UUID] { items[id]?.children ?? [] }

        /// What SidebarIntegrity checks of the tree: links agree both ways, nothing listed twice, no cycle.
        var isSound: Bool {
            for (id, it) in items {
                if Set(it.children).count != it.children.count { return false }
                if it.children.contains(where: { items[$0]?.parentID != id }) { return false }
                if let p = it.parentID, items[p]?.children.contains(id) != true { return false }
                var seen: Set<UUID> = [id]
                var up = it.parentID
                while let u = up {
                    if !seen.insert(u).inserted { return false }
                    up = items[u]?.parentID
                }
            }
            return true
        }
    }

    @Test func newestStepComesFirstAcrossCloseMoveAndClear() {
        var undo = SidebarUndo()
        let tree = Tree()
        undo.record(.init(SidebarUndo.closeTab, .reopen))
        undo.record(.init(SidebarUndo.move(count: 1), .tree(tree.snapshot(), created: [])))
        undo.record(.init(SidebarUndo.clear(count: 12), .archived([UUID()], tree.snapshot())))
        #expect(undo.label == "Clear Tabs")
        #expect(undo.pop()?.label == "Clear Tabs")
        #expect(undo.label == "Move Item")
        #expect(undo.pop()?.label == "Move Item")
        #expect(undo.pop()?.kind == .reopen)
        #expect(undo.pop() == nil && undo.label == nil)
    }

    @Test func labelsAreArcs() {
        #expect(SidebarUndo.move(count: 1) == "Move Item")
        #expect(SidebarUndo.move(count: 2) == "Move Items")
        #expect(SidebarUndo.clear(count: 1) == "Clear Tab")
        #expect(SidebarUndo.clear(count: 5) == "Clear Tabs")
        #expect(SidebarUndo.newFolder == "New Folder…")
        #expect(SidebarUndo.moveSpace == "Move Space")
        #expect(SidebarUndo.removeHeader == "Remove Header")
        #expect(SidebarUndo.tidy == "Tidy Tabs")
    }

    @Test func keepsTheNewestHundredSteps() {
        var undo = SidebarUndo()
        for i in 0..<(SidebarUndo.limit + 5) { undo.record(.init("step \(i)", .reopen)) }
        #expect(undo.entries.count == SidebarUndo.limit)
        #expect(undo.entries.first?.label == "step 5")
        #expect(undo.label == "step \(SidebarUndo.limit + 4)")
    }

    /// Tidy's own undo only while it is the newest step; a run that moved nothing takes it off.
    @Test func tidyIsUndoneOnlyAsTheNewestStep() {
        var undo = SidebarUndo()
        let sid = UUID(), moved = [UUID()]
        undo.record(.init(SidebarUndo.tidy, .tidy(spaceID: sid, todayBefore: [], moved: moved)))
        #expect(undo.newestTidy?.moved == moved)
        undo.record(.init(SidebarUndo.closeTab, .reopen))
        #expect(undo.newestTidy == nil)
        undo.dropNewestTidy()
        #expect(undo.entries.count == 2)
        _ = undo.pop()
        undo.dropNewestTidy()
        #expect(undo.entries.isEmpty)
    }

    /// ⇧⌘T reopened a close on its own: the newest close goes, whatever came after it, and nothing else does.
    @Test func reopenTakesTheNewestCloseOff() {
        var undo = SidebarUndo()
        undo.record(.init(SidebarUndo.closePeek, .reopen))
        undo.record(.init(SidebarUndo.newFolder, .tree(.init(containers: []), created: [])))
        undo.record(.init(SidebarUndo.closeTab, .reopen))
        undo.record(.init(SidebarUndo.moveSpace, .spaceOrder([])))
        undo.dropNewestReopen()
        #expect(undo.entries.map(\.label) == [SidebarUndo.closePeek, SidebarUndo.newFolder, SidebarUndo.moveSpace])
        undo.dropNewestReopen()
        #expect(undo.entries.map(\.label) == [SidebarUndo.newFolder, SidebarUndo.moveSpace])
        undo.dropNewestReopen()
        #expect(undo.entries.count == 2)
    }

    @Test func aMovedTabGoesBackToItsParentAndIndex() {
        var tree = Tree()
        let a = tree.tab("a", in: tree.today), b = tree.tab("b", in: tree.today), c = tree.tab("c", in: tree.today)
        let folder = tree.add(.folder("F", parent: tree.pinned))
        let d = tree.tab("d", in: folder)
        let before = tree.snapshot()
        tree.move(b, to: folder, at: 0)
        tree.restore(before)
        #expect(tree.children(tree.today) == [a, b, c])
        #expect(tree.children(folder) == [d])
        #expect(tree.items[b]?.parentID == tree.today)
        #expect(tree.isSound)
    }

    /// Delete Folder: the folder went with its nested folder; the tabs came back from the archive at the top of
    /// Today. Undo puts the folders back, filled, where they were.
    @Test func aDeletedFolderComesBackWithItsTabs() {
        var tree = Tree()
        let first = tree.tab("first", in: tree.pinned)
        let folder = tree.add(.folder("Work", parent: tree.pinned))
        let x = tree.tab("x", in: folder)
        let inner = tree.add(.folder("Inner", parent: folder))
        let y = tree.tab("y", in: inner)
        let last = tree.tab("last", in: tree.pinned)
        let before = tree.snapshot()
        let saved = (tree.items[x]!, tree.items[y]!)
        tree.remove(folder)
        for var t in [saved.0, saved.1] {
            t.parentID = tree.today
            tree.items[t.id] = t
            tree.items[tree.today]!.children.insert(t.id, at: 0)
        }
        tree.restore(before)
        #expect(tree.children(tree.pinned) == [first, folder, last])
        #expect(tree.children(folder) == [x, inner] && tree.children(inner) == [y])
        #expect(tree.items[folder]?.title == "Work")
        #expect(tree.children(tree.today).isEmpty)
        #expect(tree.isSound)
    }

    /// Clear: every tab comes back in its order, and a split that collapsed when its panes left is whole again.
    @Test func clearedTabsComeBackInOrderWithTheirSplit() {
        var tree = Tree()
        let tabs = (0..<5).map { tree.tab("t\($0)", in: tree.today) }
        let split = tree.add(.split(parent: tree.today))
        let panes = [tree.tab("left", in: split), tree.tab("right", in: split)]
        let before = tree.snapshot()
        let saved = (tabs + panes).map { tree.items[$0]! }
        for id in tabs + panes { tree.remove(id) }
        tree.remove(split)
        // The archive puts each at the top of Today, as restoreArchived does.
        for var t in saved {
            t.parentID = tree.today
            tree.items[t.id] = t
            tree.items[tree.today]!.children.insert(t.id, at: 0)
        }
        tree.restore(before)
        #expect(tree.children(tree.today) == tabs + [split])
        #expect(tree.children(split) == panes)
        #expect(tree.isSound)
    }

    @Test func itemsThatWentAreSkippedAndNewOnesKeepTheirPlace() {
        var tree = Tree()
        let a = tree.tab("a", in: tree.today), b = tree.tab("b", in: tree.today), c = tree.tab("c", in: tree.today)
        let before = tree.snapshot()
        tree.move(c, to: tree.today, at: 0)
        tree.remove(b)
        let fresh = tree.tab("fresh", in: tree.today)
        tree.move(fresh, to: tree.today, at: 0)
        tree.restore(before)
        #expect(tree.children(tree.today) == [fresh, a, c])
        #expect(tree.items[b] == nil)
        #expect(tree.isSound)
    }

    /// A folder whose section is gone (its space deleted) isn't made again out of nothing.
    @Test func aFolderWhoseParentWentStaysGone() {
        var tree = Tree()
        let outer = tree.add(.folder("Outer", parent: tree.pinned))
        let inner = tree.add(.folder("Inner", parent: outer))
        let before = SidebarUndo.Snapshot(containers: [tree.items[outer]!, tree.items[inner]!])
        tree.remove(outer)
        tree.restore(before)
        #expect(tree.items[outer] == nil && tree.items[inner] == nil)
        #expect(tree.isSound)
    }

    /// A step that saw F holding G, after G took F in: putting G back in F would make a loop, so it stays.
    @Test func neverPutsAFolderInsideItself() {
        var tree = Tree()
        let f = tree.add(.folder("F", parent: tree.pinned))
        let g = tree.add(.folder("G", parent: f))
        let before = SidebarUndo.Snapshot(containers: [tree.items[f]!])
        tree.move(g, to: tree.pinned, at: 0)
        tree.move(f, to: g, at: 0)
        tree.restore(before)
        #expect(tree.items[g]?.parentID == tree.pinned && tree.items[f]?.parentID == g)
        #expect(tree.isSound)
    }

    @Test(arguments: [
        ([1, 2, 3], [3, 2, 1], [1, 2, 3]),
        ([1, 2, 3], [9, 1, 2, 3], [9, 1, 2, 3]),
        ([1, 2, 3], [1, 2, 3, 9], [1, 2, 3, 9]),
        ([1, 2], [2, 9, 1], [1, 9, 2]),
        ([], [4, 5], [4, 5]),
    ])
    func savedOrderWithNewOnesInPlace(saved: [Int], current: [Int], expected: [Int]) {
        let ids = (0...9).map { _ in UUID() }
        let order = SidebarUndo.order(saved: saved.map { ids[$0] }, current: current.map { ids[$0] })
        #expect(order == expected.map { ids[$0] })
    }
}
