import CraCore
import Testing

/// The order AppDelegate.bootstrapIfNeeded runs its set-up in (it runs each stage from this list):
/// the first frame commits after only what it, a link or the first click or key needs.
struct LaunchStepsTests {
    /// A link that started Cra, a page's request (an extension's welcome page, chrome.tabs.create)
    /// and the first click or key all land in the pass that shows the windows, so their handlers and
    /// the menus' key equivalents are in place by then, never a turn later.
    @Test func handlersAndMenusPrecedeShow() {
        for step: LaunchSteps.Step in [.urlEvents, .menus, .keyMonitors, .commandFile, .pageHandlers, .pendingURLs, .activate] {
            #expect(step.stage < .afterFirstFrame, "\(step)")
        }
        let show = LaunchSteps.steps(.beforeShow)
        // Handlers before the links that need them.
        #expect(show.firstIndex(of: .pageHandlers)! < show.firstIndex(of: .pendingURLs)!)
        #expect(LaunchSteps.steps(.beforeWindows).prefix(2) == [.urlEvents, .menus])
    }

    /// Auto-archive runs before the windows are made, so a tab due to go is never drawn first.
    @Test func autoArchivePrecedesWindows() {
        #expect(LaunchSteps.Step.autoArchive.stage == .beforeWindows)
        #expect(LaunchSteps.steps(.beforeWindows).last == .autoArchive)
    }

    /// The services nothing on screen waits for come after the first frame, in their old order.
    @Test func servicesWaitForTheFirstFrame() {
        #expect(LaunchSteps.steps(.afterFirstFrame) == [
            .handoff, .mcpServer, .settingsSync, .sharing, .sidebarCheck, .liveFolders, .historyProfiles, .pageHistoryPrune,
        ])
        // Every step in exactly one stage.
        let all = LaunchSteps.steps(.beforeWindows) + LaunchSteps.steps(.beforeShow) + LaunchSteps.steps(.afterFirstFrame)
        #expect(all == LaunchSteps.Step.allCases)
    }

    /// extensions-welcomed.json used to be rewritten on every launch, on the main thread.
    @Test(arguments: [
        // Nothing new: no welcome pages, no write.
        (["a", "b"], ["b", "a"], false, nil),
        // A new extension: its welcome page opens once, and the file learns it.
        (["a"], ["b", "a"], true, ["a", "b"]),
        // One removed: nothing new, the file forgets it (reinstalled, it is new again).
        (["a", "b"], ["a"], false, ["a"]),
        // First launch with extensions.
        ([], ["c"], true, ["c"]),
        ([], [], false, nil),
    ] as [([String], [String], Bool, [String]?)])
    func extensionsWelcomedWritesOnlyWhenTheListChanged(welcomed: [String], installed: [String], hasNew: Bool, save: [String]?) {
        let r = LaunchSteps.extensionsWelcomed(Set(welcomed), installed: installed)
        #expect(r.hasNew == hasNew)
        #expect(r.save == save)
    }
}
