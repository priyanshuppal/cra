import CraCore
import Testing

struct LiveFolderPassTests {
    /// The 15-second pass woke Cra four times a minute in the background, where it refreshes
    /// nothing; it now runs there only while a tab waits to expire.
    @Test(arguments: [
        (true, false, true),
        (true, true, true),
        (false, true, true),
        (false, false, false),
    ])
    func runsWhileActiveOrWhileATabWaitsToExpire(active: Bool, waiting: Bool, runs: Bool) {
        #expect(LiveFolderPass.runs(appActive: active, itemsWaitingToExpire: waiting) == runs)
    }

    @Test func passesEveryFifteenSeconds() {
        #expect(LiveFolderPass.interval == 15)
    }
}
