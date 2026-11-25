import CraCore
import Testing

/// Hover in Arc's ⌘T bar is its own fill, not the selection: `CommandBarSuggestionRowView` keeps `isHovered`
/// and its theme a `hoveredColor` beside `selectedColor` (Arc 1.174.3's Swift field names), and
/// `CommandBarRowHoverBackgroundColor` is black or white at 0.05 (ARC_CommandBar.bundle's Assets.car).
struct CommandBarHoverTests {
    @Test func theHoverFillIsArcsFivePercent() {
        #expect(CommandBarTones.hover(dark: false) == ArcThemeData.Color(RGB(0, 0, 0), 0.05))
        #expect(CommandBarTones.hover(dark: true) == ArcThemeData.Color(RGB(1, 1, 1), 0.05))
    }

    /// The pointer on a row leaves the selected row (the one Return opens) where the keyboard put it.
    @Test(arguments: [
        // row, selected, hovered, fill
        (0, 0, nil, CommandBarRowFill.selection),
        (1, 0, nil, .none),
        (2, 0, 2, .hover),
        (0, 0, 2, .selection),
        (1, 0, 2, .none),
        (3, 3, 3, .selection),
        (1, 3, 1, .hover),
    ] as [(Int, Int, Int?, CommandBarRowFill)])
    func aHoveredRowIsntTheSelectedOne(row: Int, selected: Int, hovered: Int?, fill: CommandBarRowFill) {
        #expect(CommandBarRowFill(row: row, selected: selected, hovered: hovered) == fill)
    }

    /// Hovering never takes the selected row's fill away: of a bar's rows, exactly the selected one is
    /// `.selection` wherever the pointer is.
    @Test func theSelectionKeepsItsFillUnderAnyHover() {
        for hovered in [nil, 0, 1, 2, 3, 4] as [Int?] {
            let fills = (0..<5).map { CommandBarRowFill(row: $0, selected: 1, hovered: hovered) }
            #expect(fills.firstIndex(of: .selection) == 1 && fills.filter { $0 == .selection }.count == 1, "hovered \(String(describing: hovered))")
            #expect(fills.filter { $0 == .hover }.count == (hovered == nil || hovered == 1 ? 0 : 1))
        }
    }

    /// Arc's ✕ (#779) is on the visited page's row the pointer is on, and on the selected one, which ⌥⌘⌫
    /// deletes; a row that can't be deleted never shows it.
    @Test(arguments: [
        (true, CommandBarRowFill.selection, true),
        (true, .hover, true),
        (true, .none, false),
        (false, .selection, false),
        (false, .hover, false),
    ])
    func theDeleteMarkFollowsThePointer(deletable: Bool, fill: CommandBarRowFill, shows: Bool) {
        #expect(SuggestionDeletion.showsMark(deletable: deletable, fill: fill) == shows)
    }
}
