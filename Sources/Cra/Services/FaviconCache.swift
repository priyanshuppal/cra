import AppKit
import CryptoKit
import ImageIO
import Observation

/// One key's change counter (CraCore's ItemSignal, for favicons): a view that read a key's icon
/// depends on this, not on every icon.
@MainActor
@Observable
final class FaviconKeySignal {
    var version = 0
}

/// Favicons keyed by host or by a tab's own icon (FaviconKey). Chromium hands us PNG bytes through the bridge;
/// we keep them in memory and on disk so the sidebar is populated on launch
/// before any tab has loaded (Arc: SidebarItemsFaviconCache).
@MainActor
@Observable
final class FaviconCache {
    private static let persistenceQueue = DispatchQueue(label: "dk.kildahl.cra.favicons", qos: .utility)
    /// Observed key by key (`signals`), not as a whole: as one observed dictionary, every favicon a page
    /// reported rebuilt every space's list in every window, the icon unchanged or not.
    @ObservationIgnored private var images: [String: NSImage] = [:]
    @ObservationIgnored private var attemptedDiskLoad: Set<String> = []
    /// What reads a key depends on its signal, bumped when that key's icon changes.
    @ObservationIgnored private var signals: [String: FaviconKeySignal] = [:]
    /// A digest of each stored icon's pixels, so the same icon reported again changes nothing. Not the
    /// pixels themselves: those were a second copy of every icon in memory.
    @ObservationIgnored private var pixels: [String: SHA256.Digest] = [:]
    /// Keys whose file holds the icon in memory: storing the same pixels again needn't write it.
    @ObservationIgnored private var onDisk: Set<String> = []
    /// Keys `prefetch` is reading off the main thread, and which reset() they were asked after.
    @ObservationIgnored private var loading: Set<String> = []
    @ObservationIgnored private var generation = 0
    /// What `whenLoaded` holds until a loading key lands.
    @ObservationIgnored private var landing: [String: [() -> Void]] = [:]
    /// Keys whose file write is still queued: trimmed, they would read a file that isn't there yet, and
    /// SiteIconQueue asks for a site's icon once a launch.
    @ObservationIgnored private var writing: [String: Int] = [:]

    /// FaviconKey.key(for:), for code written before it moved to CraCore (#51).
    static func key(for urlString: String) -> String? { FaviconKey.key(for: urlString) }

    func image(forKey key: String?) -> NSImage? {
        guard let key else { return nil }
        observeKey(key)
        if let img = images[key] { return img }
        // On its way (prefetch): until it lands, which tells whoever asked, the site's icon if it is in memory.
        // Not read from disk here, which is what prefetch spares the main thread.
        if loading.contains(key) {
            let site = FaviconKey.siteKey(of: key)
            guard site != key else { return nil }
            observeKey(site)
            return images[site]
        }
        if !attemptedDiskLoad.contains(key) {
            attemptedDiskLoad.insert(key)
            let file = AppPaths.favicons.appendingPathComponent(Self.fileName(key))
            // Read, not changed: whoever asks next gets it too, so no one is told.
            if let img = NSImage(contentsOf: file) {
                images[key] = img
                onDisk.insert(key)
                return img
            }
        }
        // A tab's own icon not on disk (cleared, or saved by an incognito page): the site's (#211).
        let site = FaviconKey.siteKey(of: key)
        return site == key ? nil : image(forKey: site)
    }

    func image(for urlString: String) -> NSImage? { image(forKey: FaviconKey.key(for: urlString)) }

    /// Whether `key`'s icon is being read off the main thread: a row without it waits for it rather than
    /// fetching the site's (SiteIconLoader).
    func isLoading(_ key: String?) -> Bool { key.map(loading.contains) ?? false }

    /// Runs `done` once `key` has landed from a prefetch, or right away when it isn't loading: for a list
    /// that observes nothing (Library ▸ Boosts, the command bar) and reloads itself.
    func whenLoaded(_ key: String?, _ done: @escaping () -> Void) {
        guard let key, loading.contains(key) else { done(); return }
        landing[key, default: []].append(done)
    }

    private func landed(_ key: String) { landing.removeValue(forKey: key)?.forEach { $0() } }

    /// Reads the icons of `keys` that aren't in memory yet from disk on the persistence queue, decoded there
    /// with their glyph tone worked out, and hands them over in one batch: a space's list asks for its rows'
    /// icons before they are shown, so the main thread neither reads, decodes nor draws them (it did, the
    /// first time each key was shown). `done` runs once they have landed.
    func prefetch(_ keys: [String], done: (() -> Void)? = nil) {
        var wanted: [String] = []
        for key in keys where images[key] == nil && !attemptedDiskLoad.contains(key) && !loading.contains(key) {
            attemptedDiskLoad.insert(key)
            loading.insert(key)
            wanted.append(key)
        }
        guard !wanted.isEmpty else { done?(); return }
        let dir = AppPaths.favicons
        let files = wanted.map { dir.appendingPathComponent(Self.fileName($0)) }
        let generation = generation
        Self.persistenceQueue.async {
            let read = files.map(Self.decode)
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self.land(Array(zip(wanted, read)), generation: generation)
                    done?()
                }
            }
        }
    }

    private struct Decoded: @unchecked Sendable {
        var image: CGImage
        var size: NSSize
        var tone: Bool??
    }

    /// A favicon file decoded now (not on first draw), at the size NSImage(contentsOf:) would give it.
    nonisolated private static func decode(_ file: URL) -> Decoded? {
        guard let source = CGImageSourceCreateWithURL(file as CFURL, nil), CGImageSourceGetCount(source) > 0,
              let image = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary)
        else { return nil }
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        func points(_ pixels: Int, _ dpi: CFString) -> CGFloat {
            let d = (props?[dpi] as? Double).flatMap { $0 > 0 ? $0 : nil } ?? 72
            return CGFloat(pixels) * 72 / CGFloat(d)
        }
        return Decoded(image: image, size: NSSize(width: points(image.width, kCGImagePropertyDPIWidth),
                                                  height: points(image.height, kCGImagePropertyDPIHeight)),
                       tone: tone(of: image))
    }

    /// A prefetch's batch: what is still awaited and not stored meanwhile goes in, and whoever read
    /// a key in it as missing is told. An icon stored meanwhile stays, and told them already.
    private func land(_ batch: [(String, Decoded?)], generation: Int) {
        guard generation == self.generation else { return }
        for (key, decoded) in batch where loading.remove(key) != nil {
            if images[key] == nil {
                if let decoded {
                    images[key] = NSImage(cgImage: decoded.image, size: decoded.size)
                    onDisk.insert(key)
                    if let tone = decoded.tone { glyphTone[key] = .some(tone) }
                }
                notify(key)
            }
            landed(key)
        }
    }

    /// Depend on the icon `image(forKey:)` gives for `key` without reading it: the key's own and the
    /// site's it falls back to. A list builds its rows' models later, outside its observation.
    func observe(_ key: String?) {
        guard let key else { return }
        observeKey(key)
        let site = FaviconKey.siteKey(of: key)
        if site != key { observeKey(site) }
    }

    private func observeKey(_ key: String) { _ = signal(key).version }

    private func notify(_ key: String) { signals[key]?.version &+= 1 }

    private func signal(_ key: String) -> FaviconKeySignal {
        if let s = signals[key] { return s }
        let s = FaviconKeySignal()
        signals[key] = s
        return s
    }

    @ObservationIgnored private var dominant: [String: String] = [:]
    @ObservationIgnored private var selectionPalettes: [String: [String]] = [:]

    /// Spatial logo colors for the selected favorite's outline, cached until the icon changes.
    func selectionColors(forKey key: String?) -> [String]? {
        guard let key else { return nil }
        observeKey(key)
        if let colors = selectionPalettes[key] { return colors }
        guard let image = image(forKey: key),
              let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let size = 16
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        guard let context = CGContext(data: &pixels, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        else { return nil }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: size, height: size))
        let colors = FavoriteSelectionTint.sample(rgba: pixels, width: size, height: size)
        selectionPalettes[key] = colors
        return colors
    }

    /// Average colour of the favicon's opaque pixels as "#RRGGBB" (Arc tints
    /// the toolbar with the favicon's dominant colour when a page has no
    /// theme-color).
    func dominantColor(forKey key: String?) -> String? {
        guard let key else { return nil }
        observeKey(key)
        if let c = dominant[key] { return c.isEmpty ? nil : c }
        guard let img = image(forKey: key), let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let w = 16, h = 16
        var buf = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &buf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.interpolationQuality = .medium
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var r = 0, g = 0, b = 0, n = 0
        for i in stride(from: 0, to: buf.count, by: 4) where buf[i + 3] > 200 {
            r += Int(buf[i]); g += Int(buf[i + 1]); b += Int(buf[i + 2]); n += 1
        }
        guard n > 40 else { dominant[key] = ""; return nil }
        let hex = String(format: "#%02X%02X%02X", r / n, g / n, b / n)
        dominant[key] = hex
        return hex
    }

    @ObservationIgnored private var glyphTone: [String: Bool?] = [:]

    /// For a one-color gray glyph on a transparent background (GitHub's
    /// octocat, black or white depending on the page's color scheme): true when
    /// it is dark, false when light, nil for any other icon. Such glyphs vanish
    /// on a tile of their own tone. Custom icons are left as picked, but for a picked symbol (#640),
    /// drawn in black so that it turns light on a dark space as a site's glyph does.
    func glyphIsDark(forKey key: String?) -> Bool? {
        guard let key, !Self.isCustom(key) || TabCustomIcon.followsTheme(key: key) else { return nil }
        observeKey(key)
        if let v = glyphTone[key] { return v }
        guard let img = image(forKey: key), let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let v = Self.tone(of: cg) else { return nil }
        glyphTone[key] = .some(v)
        return v
    }

    /// Whether `key`'s glyph tone is known, so glyphIsDark answers without drawing the icon.
    func knowsGlyphTone(forKey key: String) -> Bool { glyphTone[key] != nil }

    /// GlyphTone's answer for an image drawn at its size: `.some(nil)` for an icon that isn't a gray glyph,
    /// nil when it couldn't be drawn. Off the main thread too (prefetch).
    nonisolated private static func tone(of cg: CGImage) -> Bool?? {
        let side = GlyphTone.side
        var buf = [UInt8](repeating: 0, count: side * side * 4)
        let drawn = buf.withUnsafeMutableBytes { bytes -> Bool in
            guard let ctx = CGContext(data: bytes.baseAddress, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        return drawn ? .some(GlyphTone.isDark(rgba: buf, width: side, height: side)) : nil
    }

    /// Forget in-memory state so files added on disk (imports) are picked up.
    func reset() {
        images = [:]
        attemptedDiskLoad = []
        pixels = [:]
        onDisk = []
        loading = []
        generation += 1
        // The batches asked before this one are dropped as they land: what waits on them is told now.
        let waiting = landing
        landing = [:]
        waiting.values.forEach { $0.forEach { $0() } }
        dominant = [:]
        selectionPalettes = [:]
        glyphTone = [:]
        for key in signals.keys { notify(key) }
    }

    /// As the Mac runs short of memory: keeps the icons of `keeping` (and the site icons they fall back
    /// to, CacheTrim) and lets the rest go. Each dropped key reads its file again when it is next shown.
    /// What a view shows keeps its image; no one is told.
    func trimForMemoryPressure(keeping: Set<String>) {
        let keep = CacheTrim.survivors(cached: images.keys, keeping: keeping)
        for key in images.keys where !keep.contains(key) && writing[key] == nil {
            images[key] = nil
            attemptedDiskLoad.remove(key)
            pixels[key] = nil
            onDisk.remove(key)
            dominant[key] = nil
            selectionPalettes[key] = nil
            glyphTone[key] = nil
        }
    }

    static func isCustom(_ key: String) -> Bool { key.hasPrefix("custom-") }

    /// Fits an image the user picked into a 256px square and caches it under a
    /// fresh key, so a replaced icon never shows a stale copy.
    func importCustomIcon(from url: URL) -> String? {
        NSImage(contentsOf: url).flatMap { importCustomIcon($0, prefix: "custom-") }
    }

    /// A picture as a custom icon under a fresh key that starts with `prefix` (TabCustomIcon).
    func importCustomIcon(_ src: NSImage, prefix: String) -> String? {
        guard src.size.width > 0, src.size.height > 0,
              let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 256, pixelsHigh: 256, bitsPerSample: 8,
                                         samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0),
              let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        let side: CGFloat = 256
        let scale = min(side / src.size.width, side / src.size.height)
        let size = NSSize(width: src.size.width * scale, height: src.size.height * scale)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        ctx.imageInterpolation = .high
        src.draw(in: NSRect(x: (side - size.width) / 2, y: (side - size.height) / 2, width: size.width, height: size.height))
        NSGraphicsContext.restoreGraphicsState()
        rep.size = NSSize(width: 128, height: 128)
        let img = NSImage(size: rep.size)
        img.addRepresentation(rep)
        let key = prefix + UUID().uuidString.lowercased()
        store(img, forKey: key)
        return key
    }

    func removeCustomIcon(_ key: String) {
        guard Self.isCustom(key) else { return }
        images[key] = nil
        pixels[key] = nil
        onDisk.remove(key)
        loading.remove(key)
        notify(key)
        landed(key)
        try? FileManager.default.removeItem(at: AppPaths.favicons.appendingPathComponent(Self.fileName(key)))
    }

    /// `persist` false keeps the icon in memory only (incognito pages).
    /// The same pixels again (a page reports its icon on every load, BrowserManager stores it under
    /// the site's key and the tab's) change nothing: no one is told, and the file isn't written again.
    func store(_ image: NSImage, forKey key: String, persist: Bool = true) {
        let new = Self.fingerprint(of: image)
        if let old = images[key], new != nil, (persist ? onDisk.contains(key) : true),
           old === image || new == (pixels[key] ?? Self.fingerprint(of: old)) {
            pixels[key] = new
            return
        }
        dominant[key] = nil
        glyphTone[key] = nil
        images[key] = image
        pixels[key] = new
        selectionPalettes[key] = nil
        notify(key)
        guard persist else { onDisk.remove(key); return }
        onDisk.insert(key)
        let file = AppPaths.favicons.appendingPathComponent(Self.fileName(key))
        writing[key, default: 0] += 1
        Self.persistenceQueue.async {
            if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: file, options: .atomic)
            }
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    let left = (self.writing[key] ?? 1) - 1
                    self.writing[key] = left > 0 ? left : nil
                }
            }
        }
    }

    /// A digest of an icon's decoded pixels and their layout: equal for the same icon however it arrived.
    private static func fingerprint(of image: NSImage) -> SHA256.Digest? {
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil), let bytes = cg.dataProvider?.data else { return nil }
        var hash = SHA256()
        for n in [cg.width, cg.height, cg.bytesPerRow, cg.bitsPerPixel, Int(cg.bitmapInfo.rawValue)] {
            withUnsafeBytes(of: n) { hash.update(bufferPointer: $0) }
        }
        hash.update(data: bytes as Data)
        return hash.finalize()
    }

    nonisolated static func fileName(_ key: String) -> String {
        let safe = key.map { $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" ? String($0) : "_" }.joined()
        return safe + ".png"
    }

    /// The most pixels a side of an icon file may claim: a small file can claim 40000 and cost a GB.
    nonisolated static let largestSource = 1024

    /// An icon file's bytes (another browser's store, a site) as a PNG at most `side` px on its long
    /// side. ImageIO shrinks a bitmap without decoding it at full size; AppKit draws an SVG small.
    nonisolated static func png(_ data: Data, side: Int = 64) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(source) > 0 else {
            return NSImage(data: data).flatMap { png($0, side: CGFloat(side)) }
        }
        // An .ico holds several sizes: the widest one not claiming too many pixels.
        let sizes = (0..<CGImageSourceGetCount(source)).compactMap { i -> (index: Int, width: Int)? in
            guard let p = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
                  let w = p[kCGImagePropertyPixelWidth] as? Int, let h = p[kCGImagePropertyPixelHeight] as? Int,
                  w > 0, h > 0, max(w, h) <= largestSource else { return nil }
            return (i, w)
        }
        guard let pick = sizes.max(by: { $0.width < $1.width }) else { return nil }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: side,
                                        kCGImageSourceCreateThumbnailWithTransform: true]
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(source, pick.index, options as CFDictionary) else { return nil }
        return NSBitmapImageRep(cgImage: thumb).representation(using: .png, properties: [:])
    }

    /// An image as a PNG at most `side` px on its long side, drawn at that size: for an image made in
    /// code or an SVG, which can declare any size (drawn at it, one ran a 0.1.43 import out of memory).
    nonisolated static func png(_ img: NSImage, side: CGFloat = 64) -> Data? {
        guard img.size.width > 0, img.size.height > 0 else { return nil }
        let scale = min(1, side / max(img.size.width, img.size.height))
        let w = max(1, Int((img.size.width * scale).rounded())), h = max(1, Int((img.size.height * scale).rounded()))
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                                         hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        img.draw(in: NSRect(x: 0, y: 0, width: w, height: h), from: .zero, operation: .copy, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])
    }
}
