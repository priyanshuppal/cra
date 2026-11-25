import CoreGraphics
import CraCore
import Testing

/// Arc's missing-favicon square (`FaviconBackground` in Arc 1.174.3's ARC_Favicons.bundle):
/// the sidebar, the tab switcher and the back/forward menu share it.
struct FaviconPlaceholderTests {
    @Test func theSquareIsArcsAsset() {
        #expect(FaviconPlaceholder.side == 14)
        #expect(FaviconPlaceholder.slot == 16)
        #expect(FaviconPlaceholder.cornerRadius == 3.6)
    }

    @Test(arguments: [
        (dark: true, white: 1.0, alpha: 0.14),
        (dark: false, white: 0.0, alpha: 0.10),
    ])
    func theTintIsFaintWhiteOnDarkAndFaintBlackOnLight(dark: Bool, white: Double, alpha: Double) {
        #expect(FaviconPlaceholder.white(dark: dark) == CGFloat(white))
        #expect(FaviconPlaceholder.alpha(dark: dark) == CGFloat(alpha))
    }

    @Test func theMenuDrawsItBrighterOnItsDarkFill() {
        #expect(FaviconPlaceholder.menuAlpha == 0.35)
        #expect(FaviconPlaceholder.menuAlpha > FaviconPlaceholder.alpha(dark: true))
    }

    @Test(arguments: [
        (slot: 16.0, frame: CGRect(x: 1, y: 1, width: 14, height: 14), radius: 3.6),
        (slot: 32.0, frame: CGRect(x: 2, y: 2, width: 28, height: 28), radius: 7.2),
        (slot: 8.0, frame: CGRect(x: 0.5, y: 0.5, width: 7, height: 7), radius: 1.8),
    ])
    func theSquareIsCentredInItsSlotAndScalesWithIt(slot: Double, frame: CGRect, radius: Double) {
        #expect(FaviconPlaceholder.frame(inSlot: CGFloat(slot)) == frame)
        #expect(abs(FaviconPlaceholder.cornerRadius(inSlot: CGFloat(slot)) - CGFloat(radius)) < 0.0001)
    }

    @Test func theBackForwardMenuUsesTheSameSquare() {
        #expect(BackForwardMenu.Layout.placeholderSize == FaviconPlaceholder.side)
        #expect(BackForwardMenu.Layout.faviconSize == FaviconPlaceholder.slot)
    }
}
