import Foundation

/// Sidebar tones Cra takes from Arc as an ink and its opacity over the space's colour: mostly white on dark
/// themes and black on light ones. Measured on Arc 1.172.1 at 1x and 2x, 9 Nov 2026 (GitHub #293), in a
/// light vibrant space and a dark one.
///
/// The tab rows' tones come from Arc 1.174.3's asset catalogue (ARCClients_BaseAssets.bundle's Assets.car,
/// read with `assetutil --info`, 26 Nov 2026). Its dark-appearance white is Display P3 (0.98, 0.984, 1),
/// drawn here as white. The same catalogue's SidebarItemBackground and SidebarItemHoveredBackground (light
/// 0.05 / 0.10, dark 0.10 / 0.15) are within half a percent of the pill tones measured live below.
public enum SidebarTones {
    /// White or black at `alpha`.
    public struct Tone: Equatable, Sendable {
        public var white: Bool
        public var alpha: Double

        public init(white: Bool, alpha: Double) {
            self.white = white
            self.alpha = alpha
        }
    }

    /// The space header's title and a tab group's name: dimmer than the rest of the secondary text.
    /// Arc: white 0.45 over a dark theme, black 0.46 over a light one (Cra had 0.5).
    public static func sectionTitle(dark: Bool) -> Tone {
        Tone(white: dark, alpha: dark ? 0.45 : 0.46)
    }

    /// The sidebar URL pill and a favorite tile at rest. Arc: black 0.045 on light themes, white 0.095 on
    /// dark ones (Cra had 0.08 there).
    public static func pill(dark: Bool) -> Tone {
        Tone(white: dark, alpha: dark ? 0.095 : 0.045)
    }

    /// The pill and the tiles under the pointer, one hover for both: a shade darker on light themes and
    /// lighter on dark ones. Arc: black 0.09 and white 0.145. Cra's pill turned white 0.74 on light themes.
    public static func pillHover(dark: Bool) -> Tone {
        Tone(white: dark, alpha: dark ? 0.145 : 0.09)
    }

    /// The open tab's row (and every row drawn as the open one: a split, the ⌘T bar's New Tab row). Arc's
    /// TabCellBackgroundCurrent: white 0.85 on light themes, white 0.20 on dark ones. Cra had 0.74 and 0.13
    /// from its first commit, so on a dark sidebar the open tab barely stood out.
    public static func selected(dark: Bool) -> Tone {
        Tone(white: true, alpha: dark ? 0.2 : 0.85)
    }

    /// The black shadow's opacity under the open tab's row, nil where it has none. Arc's TabCellShadowSelected:
    /// black 0.20 on light themes, clear on dark ones (Cra had 0.06). The radius and offset aren't in the
    /// catalogue; the row keeps its 3 pt, 1 pt down.
    public static func selectedShadow(dark: Bool) -> Double? {
        dark ? nil : 0.2
    }

    /// A tab picked with ⌘- or ⇧-click that isn't the open one: a tint, with no shadow. Arc's
    /// TabCellBackgroundMutiselected (sic): black 0.10 on light themes, white 0.10 on dark ones. Cra drew
    /// every pick as the open tab.
    public static func multiSelected(dark: Bool) -> Tone {
        Tone(white: dark, alpha: 0.1)
    }
}
