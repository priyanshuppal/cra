import Foundation

/// The Little Window strip's colours for the space "Open in" names (Arc's Little Arc).
///
/// Arc draws the strip from its default theme's dark palette in every space. Measured on 1.168 with
/// the yellow "Victor" space focused, and on 1.172.1, where every sampled pixel stayed the same when
/// switching between two spaces (#329). Only the space's name in "Open in <Space>" takes the space's
/// colour (Arc: `semanticColorPalette.dark.foregroundPrimary`; Victor → #FCEDBC). #549 reported the
/// unthemed strip as a bug; it stays as Arc has it.
public struct LittleStripTones: Equatable, Sendable {
    /// Arc 1.172.1's strip, left to right (10 Nov 2026, 2x window captures of a 1185 pt window: #242438 at
    /// the left end, #26243A, #292839 and #2C2439 between, #312339 at the right).
    public static let stripLeft = RGB(0x24 / 255, 0x24 / 255, 0x38 / 255)
    public static let stripRight = RGB(0x31 / 255, 0x23 / 255, 0x39 / 255)

    /// A colour at an opacity over the strip, its components in Display P3 as Arc's asset catalogue has them.
    public struct Wash: Equatable, Sendable {
        public var p3: RGB
        public var alpha: Double

        public init(p3: RGB, alpha: Double) {
            self.p3 = p3
            self.alpha = alpha
        }
    }

    /// The address pill at rest: Arc's LittleBrowserCommandBarPlaceholderBackground (Arc 1.174.3,
    /// ARC_LittleBrowser.bundle's Assets.car, `assetutil --info`, 26 Nov 2026). Dark: near-white
    /// (0.98, 0.984, 1) at 0.10, which the 1.172.1 captures read as white at 9–10 % (#329); light: near-black
    /// (0.055, 0.059, 0.063) at 0.06. Little Arc draws the strip from the dark palette.
    public static func pill(dark: Bool) -> Wash {
        Wash(p3: dark ? paleInk : darkInk, alpha: dark ? 0.10 : 0.06)
    }

    /// The pill under the pointer: …PlaceholderBackgroundHovered, the same inks at 0.15 (dark) and 0.10 (light).
    public static func pillHover(dark: Bool) -> Wash {
        Wash(p3: dark ? paleInk : darkInk, alpha: dark ? 0.15 : 0.10)
    }

    private static let paleInk = RGB(0.98, 0.984, 1)
    private static let darkInk = RGB(0.055, 0.059, 0.063)

    public var left: RGB
    public var right: RGB
    /// The space's name in "Open in <Space>", and the Peek buttons' glyphs: the space's colour (its
    /// accent, else its first colour) 72 % of the way to white.
    public var spaceName: RGB

    public init(target theme: SpaceTheme, systemDark: Bool) {
        let shown = theme.resolved(systemDark: systemDark)
        let c = HexColor.components(shown.accent ?? shown.colors.first ?? "#FFFFFF") ?? (0.5, 0.5, 0.5)
        left = Self.stripLeft
        right = Self.stripRight
        spaceName = RGB(c.r, c.g, c.b).mixed(with: .white, 0.72)
    }
}
