import Foundation

/// Whether a favicon is a one-colour gray glyph on a transparent background (GitHub's octocat,
/// black or white depending on the page's colour scheme). Such glyphs vanish on a tile of their
/// own tone, so the sidebar turns them over. Foundation only, like FavoriteSelectionTint, so
/// harnesses that build FaviconCache from source need just this file.
public enum GlyphTone {
    /// The side, in pixels, FaviconCache draws an icon at before asking.
    public static let side = 32

    /// For premultiplied RGBA pixels: true when the icon is a dark glyph, false when a light one,
    /// nil for any other icon. It has to be mostly see-through (a visible part over 20 pixels and
    /// under 85 % of them) with more than 92 % of its visible pixels the same dark or light gray.
    public static func isDark(rgba: [UInt8], width: Int, height: Int) -> Bool? {
        guard width > 0, height > 0, rgba.count == width * height * 4 else { return nil }
        var opaque = 0, dark = 0, light = 0
        for i in stride(from: 0, to: rgba.count, by: 4) where rgba[i + 3] > 128 {
            let a = Double(rgba[i + 3])
            let r = Double(rgba[i]) / a, g = Double(rgba[i + 1]) / a, b = Double(rgba[i + 2]) / a
            opaque += 1
            guard max(r, g, b) - min(r, g, b) < 0.15 else { continue }
            let l = 0.2126 * r + 0.7152 * g + 0.0722 * b
            if l < 0.3 { dark += 1 } else if l > 0.75 { light += 1 }
        }
        guard opaque > 20, opaque < width * height * 85 / 100 else { return nil }
        if Double(dark) / Double(opaque) > 0.92 { return true }
        if Double(light) / Double(opaque) > 0.92 { return false }
        return nil
    }
}
