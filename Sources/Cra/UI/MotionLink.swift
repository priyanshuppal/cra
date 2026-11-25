import AppKit

extension NSView {
    /// A display link for motion: the view's displayLink(target:selector:), asking for the
    /// screen's full rate (FrameRate) and already on the main run loop in .common mode, so it
    /// keeps ticking while a drag or a menu tracks events.
    func motionLink(target: Any, selector: Selector) -> CADisplayLink {
        displayLink(target: target, selector: selector).asMotion(maxFPS: window?.screen?.maximumFramesPerSecond)
    }
}

extension NSWindow {
    /// NSView.motionLink for a link that follows a window.
    func motionLink(target: Any, selector: Selector) -> CADisplayLink {
        displayLink(target: target, selector: selector).asMotion(maxFPS: screen?.maximumFramesPerSecond)
    }
}

private extension CADisplayLink {
    func asMotion(maxFPS: Int?) -> CADisplayLink {
        let r = FrameRate.range(maxFPS: maxFPS)
        preferredFrameRateRange = CAFrameRateRange(minimum: r.minimum, maximum: r.maximum, preferred: r.preferred)
        add(to: .main, forMode: .common)
        return self
    }
}
