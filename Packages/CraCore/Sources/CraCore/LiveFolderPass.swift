import Foundation

/// When the live folder pass runs: every 15 seconds it removes tabs whose item left a folder's
/// results more than the retention ago, then refreshes stale folders. Refreshing waits for an
/// active window (Dia's waitingForActiveWindow), so in the background the pass has only expiry
/// to do, and only while a tab is waiting to go: a background window's sidebar still shows it.
/// With nothing waiting it stops, and becoming active runs it at once and starts it again.
public enum LiveFolderPass {
    public static let interval: TimeInterval = 15

    public static func runs(appActive: Bool, itemsWaitingToExpire: Bool) -> Bool {
        appActive || itemsWaitingToExpire
    }
}
