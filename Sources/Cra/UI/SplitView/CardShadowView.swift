import AppKit

extension CALayerCornerCurve {
    /// The page card's corner curve (CraCore `CardFill.cornerCurve`, circular like Arc's), for every layer
    /// that draws the card's edge. `CardShadowView.cutout` draws the same curve, so the card meets its
    /// shadow's cut-out exactly.
    static let card: CALayerCornerCurve = CardFill.cornerCurve == .continuous ? .continuous : .circular
}

/// Arc's card shadow, fitted to its captures (Arc 1.171, light space, 2x, GitHub #178): a
/// Gaussian edge of 26 % black, 3.6 pt sigma, 0.8 pt low. Core Graphics' blur came out softer and
/// lighter than its nominal sigma (fitted on Cra's own capture), hence 31 % and a 6.5 pt blur. Drawn as a
/// stretchable image, made once per corner radius and scale, so it costs nothing per frame and
/// stretches with the card while its frame animates. The card's own area is cut out: a card
/// whose page has not painted yet shows the window behind it, not the shadow.
final class CardShadowView: NSView {
    static let alpha: CGFloat = 0.31, blur: CGFloat = 6.5, drop: CGFloat = 0.8, sigma: CGFloat = 3.6
    /// How far the shadow reaches past the card.
    static let pad: CGFloat = ceil(3 * sigma + drop)
    var cornerRadius: CGFloat = 0 { didSet { if cornerRadius != oldValue { refresh() } } }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.contentsGravity = .resize
    }

    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func viewDidChangeBackingProperties() { super.viewDidChangeBackingProperties(); refresh() }

    private func refresh() {
        let scale = window?.backingScaleFactor ?? 2
        guard let image = Self.image(radius: cornerRadius, scale: scale) else { layer?.contents = nil; return }
        layer?.contents = image
        layer?.contentsScale = scale
        // The middle stretches: one point between the corners on each axis.
        let side = CGFloat(image.width) / scale, mid = Self.pad + cornerRadius
        layer?.contentsCenter = CGRect(x: mid / side, y: mid / side, width: 1 / side, height: 1 / side)
    }

    /// The card's outline, which the shadow is cast from and cut along: a circular rounded rect, the
    /// curve `CALayerCornerCurve.card` gives the card's own layers.
    static func cutout(_ rect: CGRect, radius: CGFloat) -> CGPath {
        CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }

    private static var cache: [String: CGImage] = [:]

    private static func image(radius: CGFloat, scale: CGFloat) -> CGImage? {
        let key = "\(radius)@\(scale)"
        if let hit = cache[key] { return hit }
        // The card is the middle (2·radius + 1 pt square), the shadow pad around it.
        let card = 2 * radius + 1, side = card + 2 * pad
        let px = Int(ceil(side * scale))
        guard let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.scaleBy(x: scale, y: scale)
        let rect = CGRect(x: pad, y: pad, width: card, height: card)
        let path = cutout(rect, radius: radius)
        // The blurred rect: Core Graphics' shadow of a shape drawn far off the canvas, so only its
        // shadow lands.
        let far: CGFloat = 10_000
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: far * scale, height: -drop * scale), blur: blur * scale,
                      color: NSColor.black.withAlphaComponent(alpha).cgColor)
        ctx.translateBy(x: -far, y: 0)
        ctx.addPath(path)
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        // Cut the card out.
        ctx.setBlendMode(.clear)
        ctx.addPath(path)
        ctx.fillPath()
        let image = ctx.makeImage()
        cache[key] = image
        return image
    }
}
