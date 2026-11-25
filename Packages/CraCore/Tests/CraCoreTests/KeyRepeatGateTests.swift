import CraCore
import Testing

struct KeyRepeatGateTests {
    /// Times in binary fractions, so the edge is exact: 1.5 × 0.125 = 0.1875.
    @Test(arguments: [
        // A first press runs however late it is handled.
        (false, 10.0, 10.0, 0.125, true),
        (false, 10.0, 15.0, 0.125, true),
        // A repeat handled on time runs: the key is still held.
        (true, 10.0, 10.0, 0.125, true),
        (true, 10.0, 10.125, 0.125, true),
        // The edge: one and a half intervals old still runs; any older is dropped.
        (true, 10.0, 10.1875, 0.125, true),
        (true, 10.0, 10.25, 0.125, false),
        // A repeat that queued behind a slow switch is dropped.
        (true, 10.0, 11.0, 0.125, false),
        (true, 10.0, 10.0625, 0.03125, false),
    ])
    func accepts(isRepeat: Bool, eventTime: Double, now: Double, interval: Double, runs: Bool) {
        #expect(KeyRepeatGate.accepts(isRepeat: isRepeat, eventTime: eventTime, now: now, repeatInterval: interval) == runs)
    }

    @Test func appliesToTabAndSpaceStepping() {
        #expect(KeyRepeatGate.actions == ["nextTab", "previousTab", "nextSpace", "previousSpace"])
    }
}
