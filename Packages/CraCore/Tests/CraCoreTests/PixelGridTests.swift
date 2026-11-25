import CoreGraphics
import CraCore
import Testing

/// Sidebar text and icons on whole pixels, at 1x and 2x.
struct PixelGridTests {
    /// A row with a subtitle: (40 − 16 − 1 − 14) / 2 = 4.5 pt from the top. At 1x that is between two
    /// pixels; aligned, the title starts on one and keeps its 16 pt.
    @Test func theSubtitleRowsTitleLandsOnAPixelAt1x() {
        let title = CGRect(x: 36.5, y: 4.5, width: 180, height: 16)
        let aligned = PixelGrid.align(title, scale: 1)
        #expect(aligned == CGRect(x: 37, y: 5, width: 180, height: 16))
        #expect(PixelGrid.offGrid([title], scale: 1) == [0])
        #expect(PixelGrid.offGrid([aligned], scale: 1) == [])
    }

    /// At 2x half points are whole pixels already, so aligning moves nothing there.
    @Test func halfPointsStayAt2x() {
        let title = CGRect(x: 36.5, y: 4.5, width: 180, height: 16)
        #expect(PixelGrid.align(title, scale: 2) == title)
        #expect(PixelGrid.offGrid([title], scale: 2) == [])
    }

    /// A quarter point is off the grid even at 2x, and goes to the nearest pixel, never further than half of one.
    @Test(arguments: [
        (CGRect(x: 10.25, y: 3.75, width: 16, height: 16), CGFloat(2), CGRect(x: 10.5, y: 4, width: 16, height: 16)),
        (CGRect(x: 10.2, y: 3.8, width: 16, height: 16), CGFloat(1), CGRect(x: 10, y: 4, width: 16, height: 16)),
        (CGRect(x: 0, y: 0, width: 16, height: 16), CGFloat(1), CGRect(x: 0, y: 0, width: 16, height: 16)),
    ])
    func eachEdgeGoesToTheNearestPixel(rect: CGRect, scale: CGFloat, expected: CGRect) {
        let aligned = PixelGrid.align(rect, scale: scale)
        #expect(aligned == expected)
        #expect(abs(aligned.minX - rect.minX) <= 0.5 / scale)
        #expect(abs(aligned.minY - rect.minY) <= 0.5 / scale)
        #expect(PixelGrid.offGrid([aligned], scale: scale) == [])
    }

    /// A fractional size (a text field as wide as a dragged sidebar) has its far edge aligned too.
    @Test func aFractionalSizeHasBothEdgesAligned() {
        let r = PixelGrid.align(CGRect(x: 8, y: 0, width: 171.3, height: 16), scale: 1)
        #expect(r == CGRect(x: 8, y: 0, width: 171, height: 16))
    }

    /// offGrid lists only the frames whose origin is between pixels, by index.
    @Test func offGridListsTheFramesBetweenPixels() {
        let frames = [CGRect(x: 0, y: 0, width: 16, height: 16), CGRect(x: 4.5, y: 0, width: 16, height: 16),
                      CGRect(x: 2, y: 7.5, width: 10, height: 10), CGRect(x: 1.25, y: 1.25, width: 4, height: 4)]
        #expect(PixelGrid.offGrid(frames, scale: 1) == [1, 2, 3])
        #expect(PixelGrid.offGrid(frames, scale: 2) == [3])
    }
}
