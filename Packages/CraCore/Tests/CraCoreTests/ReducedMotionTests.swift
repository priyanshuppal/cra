import CraCore
import Foundation
import Testing

/// What each motion becomes with Reduce motion on, and that nothing changes with it off.
struct ReducedMotionTests {
    typealias Motion = ReducedMotion.Motion

    /// Off: every motion plays as in Arc, whether or not content changes.
    @Test(arguments: Motion.allCases, [true, false])
    func offPlaysEverythingAsIs(motion: Motion, contentChanges: Bool) {
        #expect(ReducedMotion.substitute(motion, reduce: false, contentChanges: contentChanges) == .asIs)
    }

    typealias Row = (motion: Motion, whenContentChanges: ReducedMotion.Substitute, whenRepositioning: ReducedMotion.Substitute)

    /// On: spatial moves dissolve where content changes and jump where it is only repositioned, colour stays,
    /// decoration goes.
    static let table: [Row] = [
        (.slide, .crossfade(ReducedMotion.crossfadeDuration), .instant),
        (.spring, .crossfade(ReducedMotion.crossfadeDuration), .instant),
        (.zoom, .crossfade(ReducedMotion.crossfadeDuration), .instant),
        (.flight, .instant, .instant),
        (.bounce, .instant, .instant),
        (.fade, .asIs, .asIs),
    ]

    @Test func tableCoversEveryMotion() {
        #expect(Set(Self.table.map { "\($0.motion)" }) == Set(Motion.allCases.map { "\($0)" }))
    }

    @Test(arguments: ReducedMotionTests.table)
    func onSubstitutes(row: Row) {
        #expect(ReducedMotion.substitute(row.motion, reduce: true, contentChanges: true) == row.whenContentChanges)
        #expect(ReducedMotion.substitute(row.motion, reduce: true, contentChanges: false) == row.whenRepositioning)
    }

    /// A call site that says nothing about content gets the dissolve: most moves bring something in or take it away.
    @Test func contentChangesByDefault() {
        #expect(ReducedMotion.substitute(.slide, reduce: true) == .crossfade(ReducedMotion.crossfadeDuration))
    }

    /// On, nothing travels: no spatial motion, flight or bounce plays as is.
    @Test(arguments: Motion.allCases.filter { $0 != .fade })
    func onNothingTravels(motion: Motion) {
        #expect(!ReducedMotion.substitute(motion, reduce: true).plays)
        #expect(!ReducedMotion.substitute(motion, reduce: true, contentChanges: false).plays)
    }

    /// The dissolve is short, a fifth of a second at most, and never zero (an instant change would be `.instant`).
    @Test func crossfadeIsShort() {
        #expect(ReducedMotion.crossfadeDuration > 0)
        #expect(ReducedMotion.crossfadeDuration <= 0.2)
    }

    /// The duration a site animates for under each substitute.
    @Test func durations() {
        #expect(ReducedMotion.Substitute.asIs.duration(0.4) == 0.4)
        #expect(ReducedMotion.Substitute.crossfade(0.15).duration(0.4) == 0.15)
        #expect(ReducedMotion.Substitute.instant.duration(0.4) == 0)
        #expect(ReducedMotion.Substitute.asIs.plays)
        #expect(!ReducedMotion.Substitute.crossfade(0.15).plays)
        #expect(!ReducedMotion.Substitute.instant.plays)
    }
}
