import AppKit

/// The page card's corner meets its shadow's cut-out. `CardShadowView` cuts the card out of its
/// shadow along `cutout` (a circular rounded rect); the card's layers round with
/// `CALayerCornerCurve.card`. A continuous card curve ran inside that cut near each corner, a sliver
/// with neither card nor shadow. A card layer in an off-screen window, composited by the window
/// server, against the cut-out drawn by Core Graphics at the same scale.
@main
enum CardCornersTests {
    private static var checks = 0

    @MainActor
    static func main() {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        theCardCoversItsShadowsCutout()
        print("Card corners: \(checks) checks passed")
    }

    /// At Arc's 6 pt and at the larger, concentric radii a narrow margin gives (PageMargin.cardRadius),
    /// the cut-out reaches past the card's edge by no more than the card reaches past the cut-out: what
    /// is left is the compositor's anti-aliasing, not a curve inside another. Measured on a 2x display:
    /// circular leaves 0.6–1.3 px of sliver per corner against as much overshoot; continuous left
    /// 2.9 px at 6 pt and 13.7 px at 13 pt.
    @MainActor
    private static func theCardCoversItsShadowsCutout() {
        for radius: CGFloat in [6, 10, 13] {
            let (sliver, overshoot) = corners(radius: radius)
            expect(sliver <= overshoot + 1,
                   "\(Int(radius)) pt card: its shadow's cut-out reaches \(fmt(sliver)) px past the card's corners (the card \(fmt(overshoot)) px past it)")
        }
    }

    // MARK: Helpers

    private final class OffscreenWindow: NSWindow {
        override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
    }

    /// Pixels (summed coverage, all four corners) where the cut-out covers more than the card, and
    /// where the card covers more than the cut-out.
    @MainActor
    private static func corners(radius: CGFloat) -> (sliver: Double, overshoot: Double) {
        let size = NSSize(width: 80, height: 80)
        let w = OffscreenWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        w.isReleasedWhenClosed = false
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        let root = NSView(frame: NSRect(origin: .zero, size: size))
        root.wantsLayer = true
        // Rounded as PaneCardView rounds the card.
        let card = NSView(frame: root.bounds.insetBy(dx: 10, dy: 10))
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.black.cgColor
        card.layer?.cornerRadius = radius
        card.layer?.cornerCurve = .card
        card.layer?.masksToBounds = true
        root.addSubview(card)
        w.contentView = root
        w.setFrameOrigin(NSPoint(x: -6000, y: 300))
        w.orderFront(nil)
        w.display()
        CATransaction.flush()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        defer { w.orderOut(nil) }
        // kCGWindowListOptionIncludingWindow, kCGWindowImageBoundsIgnoreFraming
        guard let image = capture(.null, 1 << 3, UInt32(w.windowNumber), 1 << 0)?.takeRetainedValue() else {
            expect(false, "the window server returned the window's pixels")
            return (0, 0)
        }
        let (width, height) = (image.width, image.height)
        let shot = bitmap(width, height)
        shot.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let a = alpha(shot, width, height)
        // Where the card is in the capture, found along the middle row and column (an off-screen window
        // on a 1x display came back a row taller, PictureInPictureCornersTests).
        let cols = (0..<width).filter { a[height / 2 * width + $0] > 127 }, rows = (0..<height).filter { a[$0 * width + width / 2] > 127 }
        guard let left = cols.first, let right = cols.last, let top = rows.first, let bottom = rows.last else {
            expect(false, "the card has pixels in the capture")
            return (0, 0)
        }
        let scale = CGFloat(right - left + 1) / card.frame.width
        // The cut-out, where CardShadowView clears its shadow, at the same scale over the same box. Rows
        // count from the top in both bitmaps.
        let ref = bitmap(width, height)
        let box = CGRect(x: left, y: height - 1 - bottom, width: right - left + 1, height: bottom - top + 1)
        ref.addPath(CardShadowView.cutout(box, radius: radius * scale))
        ref.setFillColor(NSColor.black.cgColor)
        ref.fillPath()
        let b = alpha(ref, width, height)
        var sliver = 0, overshoot = 0
        for i in 0..<a.count {
            let d = Int(b[i]) - Int(a[i])
            if d > 0 { sliver += d } else { overshoot -= d }
        }
        return (Double(sliver) / 255, Double(overshoot) / 255)
    }

    private static func bitmap(_ width: Int, _ height: Int) -> CGContext {
        CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    }

    /// Alpha by row from the top.
    private static func alpha(_ ctx: CGContext, _ width: Int, _ height: Int) -> [UInt8] {
        let p = ctx.data!.assumingMemoryBound(to: UInt8.self)
        return (0..<(width * height)).map { p[($0 / width * ctx.bytesPerRow) + ($0 % width) * 4 + 3] }
    }

    private typealias CaptureFn = @convention(c) (CGRect, UInt32, UInt32, UInt32) -> Unmanaged<CGImage>?
    private static let capture: CaptureFn = {
        // The Swift name is marked unavailable; the window server still serves a process its own windows.
        let cg = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_NOW)
        return unsafeBitCast(dlsym(cg, "CGWindowListCreateImage"), to: CaptureFn.self)
    }()

    private static func fmt(_ value: Double) -> String { String(format: "%.1f", value) }

    private static func expect(_ condition: Bool, _ message: String) {
        checks += 1
        guard condition else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }
}
