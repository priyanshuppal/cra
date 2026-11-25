import CraCore
import Foundation
import Testing

/// A page made ahead for the next tab that needs one, so a new tab doesn't wait for CEF's window.
struct SparePageTests {
    @Test func onlyChromiumPagesInAProfile() {
        #expect(SparePage.canTake(engine: .chromium, isEasel: false, incognito: false))
        // A DRM service's tab opens in WebKit; an easel is Cra's canvas; incognito has no profile.
        #expect(!SparePage.canTake(engine: .webKit, isEasel: false, incognito: false))
        #expect(!SparePage.canTake(engine: .chromium, isEasel: true, incognito: false))
        #expect(!SparePage.canTake(engine: .chromium, isEasel: false, incognito: true))
    }

    @Test func keyedByProfile() {
        #expect(SparePage.key(profilePath: nil) == "")
        #expect(SparePage.key(profilePath: "/p/Work") == "/p/Work")
        #expect(SparePage.key(profilePath: "/p/Work") != SparePage.key(profilePath: nil))
    }

    @Test func refillsAfterTheClick() {
        #expect(SparePage.refillDelay >= 1)
    }

    @Test(arguments: [
        (PerfSystemSample.Pressure.normal, true),
        (.unknown, true),
        (.warning, false),
        (.critical, false),
    ])
    func noSpareWhileMemoryIsShort(pressure: PerfSystemSample.Pressure, keeps: Bool) {
        #expect(SparePage.keeps(pressure: pressure) == keeps)
    }

    @Test func onlyTheProfileUsedLastKeepsOne() {
        let work = SparePage.key(profilePath: "/p/Work")
        let home = SparePage.key(profilePath: nil)
        #expect(SparePage.dropped(making: work, kept: [home]) == [home])
        #expect(SparePage.dropped(making: work, kept: [home, work, "/p/School"]) == [home, "/p/School"])
        #expect(SparePage.dropped(making: work, kept: [work]).isEmpty)
        #expect(SparePage.dropped(making: home, kept: []).isEmpty)
    }
}
