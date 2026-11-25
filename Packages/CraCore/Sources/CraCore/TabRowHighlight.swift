import Foundation

/// How a sidebar tab row is filled. Arc's tab cell keeps `isCurrentItem` and `isMultiSelected` apart: the
/// open tab takes TabCellBackgroundCurrent and its shadow, a tab picked with ⌘- or ⇧-click takes the
/// fainter TabCellBackgroundMutiselected with none (SidebarTones). Cra drew every pick as the open tab.
public enum TabRowHighlight: Equatable, Sendable {
    case none
    /// The open tab, picked or not: SidebarTones.selected, lifted by its shadow.
    case current
    /// Picked, and not the open tab: SidebarTones.multiSelected, flat.
    case picked

    /// `current`: the row is the open tab (and no ⌘T bar stands in for it). `picked`: the row is among the
    /// picks, and `picking` is whether there are any. While tabs are picked only the picks are filled, as
    /// before; the open tab among them keeps its own look.
    public init(current: Bool, picked: Bool, picking: Bool) {
        if picking {
            self = picked ? (current ? .current : .picked) : .none
        } else {
            self = current ? .current : .none
        }
    }

    /// Whether the row has a resting fill (a hovered row's doesn't show over it).
    public var filled: Bool { self != .none }
    /// Whether the row casts the open tab's shadow.
    public var lifted: Bool { self == .current }
}
