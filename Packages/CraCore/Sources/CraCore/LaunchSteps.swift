import Foundation

/// The order of AppDelegate.bootstrapIfNeeded's set-up around the first window. Everything in the
/// pass that orders the windows in delays their first frame, which Core Animation commits only at
/// the end of that pass; what neither that frame nor the first click or key needs waits for the
/// next turn of the main queue, and a link that started Cra opens there too, once settings sync
/// has started. AppDelegate runs each stage from this list, so
/// the tests pin the order it really runs.
public enum LaunchSteps {
    public enum Stage: Int, Comparable, Sendable {
        /// Before the browser windows are made: what decides which tabs they draw.
        case beforeWindows
        /// In the pass that orders the windows in, before its frame commits: what a page's request
        /// or the first click or key reaches.
        case beforeShow
        /// The next turn of the main queue, once the first frame is committed: services nothing
        /// on screen waits for.
        case afterFirstFrame

        public static func < (a: Stage, b: Stage) -> Bool { a.rawValue < b.rawValue }
    }

    public enum Step: String, CaseIterable, Sendable {
        /// Apple Events' open-URL handler.
        case urlEvents
        /// The menu bar, with every shortcut's key equivalent.
        case menus
        /// Arc's auto-archive pass, and the periodic timers: a tab due to go is never drawn.
        case autoArchive
        /// The key fallback and side-button monitors (the first keystroke).
        case keyMonitors
        /// CRA_COMMAND_FILE, which scenarios write to as soon as the log says it is read.
        case commandFile
        /// Sleep and wake observers.
        case systemWake
        /// Cra comes forward, or stays behind for a measured background run.
        case activate
        /// Downloads, app links, view-source, Chrome's page windows, and the stray-page,
        /// chrome.tabs.create and relaunch handlers; extensions-welcomed.json is read here.
        case pageHandlers
        /// Handoff to the iPhone (#745).
        case handoff
        /// The MCP server's socket.
        case mcpServer
        /// Settings sync's folder or iCloud.
        case settingsSync
        /// Links that started Cra (application(_:open:) before bootstrap, or before this step). After
        /// settings sync starts: a folder's first poll can replace the whole sidebar with the synced
        /// one, which would take away a link's tab made before it.
        case pendingURLs
        /// Usage stats and crash reports (their first send is 30 s later anyway).
        case sharing
        /// SidebarIntegrity's walk of the whole tree, which logs a fault per broken link.
        case sidebarCheck
        /// Live folders' timers and plug-ins.
        case liveFolders
        /// History entries from before profiles, attributed from Chromium's databases.
        case historyProfiles
        /// Saved page histories of tabs that are gone: deletes on disk.
        case pageHistoryPrune

        public var stage: Stage {
            switch self {
            case .urlEvents, .menus, .autoArchive: .beforeWindows
            case .keyMonitors, .commandFile, .systemWake, .activate, .pageHandlers: .beforeShow
            case .handoff, .mcpServer, .settingsSync, .pendingURLs, .sharing, .sidebarCheck, .liveFolders, .historyProfiles,
                 .pageHistoryPrune: .afterFirstFrame
            }
        }
    }

    /// A stage's steps, in the order they run.
    public static func steps(_ stage: Stage) -> [Step] {
        Step.allCases.filter { $0.stage == stage }
    }

    /// extensions-welcomed.json at launch: whether an extension is new since the last launch (then
    /// its welcome page opens once) and the list to write, nil when the file already says so.
    public static func extensionsWelcomed(_ welcomed: Set<String>, installed: [String]) -> (hasNew: Bool, save: [String]?) {
        let now = Set(installed)
        return (!now.isSubset(of: welcomed), now == welcomed ? nil : now.sorted())
    }
}
