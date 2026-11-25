import Foundation

/// The frame rates Cra's display links ask for: the screen's full rate, never under 60. A
/// display link left at its default may be held to a lower rate when the system saves power;
/// asking states that motion (a spring, a slide, a drag's scroll) wants every frame the
/// screen draws, 120 on a ProMotion display.
public enum FrameRate {
    public struct Range: Equatable, Sendable {
        public var minimum: Float
        public var maximum: Float
        public var preferred: Float

        public init(minimum: Float, maximum: Float, preferred: Float) {
            self.minimum = minimum
            self.maximum = maximum
            self.preferred = preferred
        }
    }

    /// When the screen's rate isn't known (no window or screen yet), what the link asks for.
    public static let fallback = 120

    /// The range for a screen of `maxFPS` frames per second (`NSScreen.maximumFramesPerSecond`,
    /// nil without a screen): 60 at the least, up to and preferring the screen's rate.
    public static func range(maxFPS: Int?) -> Range {
        let top = Float(max(maxFPS ?? fallback, 60))
        return Range(minimum: 60, maximum: top, preferred: top)
    }
}
