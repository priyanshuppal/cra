import AppKit

extension NSView {
    /// `rect`, a subview's frame in this view's coordinates, with its edges on the window's pixels
    /// (CraCore's `PixelGrid.align`, in window space). Sidebar rows pass their text, favicons and
    /// accessories through it: a part centred with `/ 2` landed on a half point, where a 1x display
    /// resamples it and the text goes soft. At 2x a half point is a whole pixel, so nothing moves
    /// there except a quarter point, by at most half a pixel. Without a window it is `rect`.
    func snap(_ rect: NSRect) -> NSRect {
        guard let window else { return rect }
        let inWindow = convert(rect, to: nil)
        return convert(PixelGrid.align(inWindow, scale: window.backingScaleFactor), from: nil)
    }
}

/// `cra://debug?offGrid=<label>[&in=rows]`: the text fields, image views and views hosting a
/// CATextLayer whose window-space origin is between pixels (CraCore's `PixelGrid.offGrid`), in the
/// whole window or only inside the sidebar's rows. Hidden and empty views don't count.
@MainActor
enum OffGridReadout {
    static func report(in window: NSWindow, rowsOnly: Bool) -> String {
        guard let content = window.contentView else { return "no window" }
        var found: [(name: String, view: NSView)] = []
        func walk(_ v: NSView, row: String?) {
            guard !v.isHidden, v.alphaValue > 0 else { return }
            let row = row ?? (v is SidebarRowView ? String(describing: type(of: v)) : nil)
            let hostsText = v.layer?.sublayers?.contains { $0 is CATextLayer && !$0.isHidden } == true
            if v is NSTextField || v is NSImageView || hostsText, v.bounds.width > 0, v.bounds.height > 0, !rowsOnly || row != nil {
                let name = String(describing: type(of: v))
                found.append((name: row.map { $0 == name ? name : "\($0)>\(name)" } ?? name, view: v))
            }
            for s in v.subviews { walk(s, row: row) }
        }
        walk(content, row: nil)
        let frames = found.map { $0.view.convert($0.view.bounds, to: nil) }
        let off = PixelGrid.offGrid(frames, scale: window.backingScaleFactor)
        guard !off.isEmpty else { return "none (\(found.count) checked at \(window.backingScaleFactor)x)" }
        return off.map { i in
            "\(found[i].name) \(frames[i].minX),\(frames[i].minY)"
        }.joined(separator: "; ")
    }
}
