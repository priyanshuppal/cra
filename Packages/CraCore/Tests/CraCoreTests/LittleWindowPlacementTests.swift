import CoreGraphics
import CraCore
import Testing

/// Where a new Little Window opens: centred, or cascaded 24 pt right and down off the one in front.
struct LittleWindowPlacementTests {
    let visible = CGRect(x: 0, y: 0, width: 1728, height: 1084)
    let size = CGSize(width: 1000, height: 700)
    var centred: CGRect { CGRect(x: 364, y: 192, width: 1000, height: 700) }

    /// No Little Window showing on the screen (Peeks parked on three tabs aren't passed): centred.
    /// Cra counted every Little Window, Peeks included, and opened this one 72 pt off the centre.
    @Test func noneShowingIsCentred() {
        #expect(LittleWindowPlacement.frame(size: size, visible: visible, others: []) == centred)
    }

    /// One in the middle: 24 pt right and 24 pt down (y up), the direction Cra always cascaded in.
    @Test func oneAtTheCentreCascades() {
        let f = LittleWindowPlacement.frame(size: size, visible: visible, others: [centred])
        #expect(f == centred.offsetBy(dx: 24, dy: -24))
    }

    /// Several, front to back: it steps off the front one, not off the count.
    @Test func severalStepOffTheFrontOne() {
        let front = centred.offsetBy(dx: 24, dy: -24)
        let f = LittleWindowPlacement.frame(size: size, visible: visible, others: [front, centred])
        #expect(f == centred.offsetBy(dx: 48, dy: -48))
        // A front one moved aside: the new one follows it, not the centre.
        let aside = CGRect(x: 100, y: 300, width: 1000, height: 700)
        #expect(LittleWindowPlacement.frame(size: size, visible: visible, others: [aside, centred])
                == CGRect(x: 124, y: 276, width: 1000, height: 700))
    }

    /// A front one of another size: the top-left corners are a step apart.
    @Test func cascadeKeepsTheTopLeftCorner() {
        let small = CGRect(x: 600, y: 600, width: 400, height: 300)
        let f = LittleWindowPlacement.frame(size: size, visible: visible, others: [small])
        #expect(f.minX == 624)
        #expect(f.maxY == small.maxY - 24)
    }

    /// The screen still holds it: a front one in the bottom-right corner leaves the new one at the edge.
    @Test func staysOnTheScreen() {
        let corner = CGRect(x: 728, y: 0, width: 1000, height: 700)
        let f = LittleWindowPlacement.frame(size: size, visible: visible, others: [corner])
        #expect(f == corner)
    }

    /// A window larger than the screen is cut to the visible area less 40 pt, and centred.
    @Test func tooBigIsCut() {
        let f = LittleWindowPlacement.frame(size: CGSize(width: 3000, height: 2000), visible: visible, others: [])
        #expect(f == CGRect(x: 20, y: 20, width: 1688, height: 1044))
    }

    /// On a screen whose visible area doesn't start at zero (a second display, the menu bar).
    @Test func followsTheScreen() {
        let left = CGRect(x: -1920, y: 40, width: 1920, height: 1015)
        let f = LittleWindowPlacement.frame(size: size, visible: left, others: [])
        #expect(f.midX == left.midX)
        #expect(f.midY == left.midY)
    }
}
