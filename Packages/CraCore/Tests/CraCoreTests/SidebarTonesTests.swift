import CraCore
import Testing

/// GitHub #293: the sidebar's section titles, URL pill and favorite tiles in Arc 1.172.1's tones.
@Suite struct SidebarTonesTests {
    @Test(.bug("https://github.com/VictorKildahl/cra/issues/293")) func sectionTitlesAreDimmerThanSecondaryText() {
        #expect(SidebarTones.sectionTitle(dark: false) == .init(white: false, alpha: 0.46))
        #expect(SidebarTones.sectionTitle(dark: true) == .init(white: true, alpha: 0.45))
    }

    @Test(.bug("https://github.com/VictorKildahl/cra/issues/293")) func pillAndTilesShareArcsHover() {
        #expect(SidebarTones.pill(dark: false) == .init(white: false, alpha: 0.045))
        #expect(SidebarTones.pill(dark: true) == .init(white: true, alpha: 0.095))
        // Hovered, the pill darkens on a light theme like a tile does; it no longer goes near-white.
        #expect(SidebarTones.pillHover(dark: false) == .init(white: false, alpha: 0.09))
        #expect(SidebarTones.pillHover(dark: true) == .init(white: true, alpha: 0.145))
    }

    /// Arc 1.174.3's TabCellBackgroundCurrent: the open tab is white 0.85 on a light sidebar and white 0.20 on a
    /// dark one. Cra's 0.74 and 0.13 left the open tab hard to find on a dark sidebar.
    @Test func selectedTabIsArcsCurrentCell() {
        #expect(SidebarTones.selected(dark: false) == .init(white: true, alpha: 0.85))
        #expect(SidebarTones.selected(dark: true) == .init(white: true, alpha: 0.2))
    }

    /// Arc's TabCellShadowSelected: black 0.20 under the open tab on a light sidebar, none on a dark one.
    @Test func selectedTabShadowIsLightOnly() {
        #expect(SidebarTones.selectedShadow(dark: false) == 0.2)
        #expect(SidebarTones.selectedShadow(dark: true) == nil)
    }

    /// Arc's TabCellBackgroundMutiselected: a picked tab is a faint tint, black 0.10 on light and white 0.10 on
    /// dark, never the open tab's white.
    @Test func pickedTabIsArcsMultiSelectedCell() {
        #expect(SidebarTones.multiSelected(dark: false) == .init(white: false, alpha: 0.1))
        #expect(SidebarTones.multiSelected(dark: true) == .init(white: true, alpha: 0.1))
        for dark in [false, true] {
            #expect(SidebarTones.multiSelected(dark: dark) != SidebarTones.selected(dark: dark))
            #expect(SidebarTones.multiSelected(dark: dark).alpha < SidebarTones.selected(dark: dark).alpha)
        }
    }
}
