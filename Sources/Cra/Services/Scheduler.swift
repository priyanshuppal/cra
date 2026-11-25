import Foundation

/// The clock behind every decision Cra makes from time: auto-archive, tab sleep, live folder
/// expiry, the command file poll. The app runs on `LiveScheduler`; a test host passes a manual
/// one and advances it, so a 30-minute timer runs in a millisecond (Tests/Support/ManualScheduler).
/// Animation and hover delays stay on Timer: they perform, they don't decide.
@MainActor
protocol Scheduler: AnyObject {
    var now: Date { get }
    @discardableResult func after(_ delay: TimeInterval, _ work: @escaping @MainActor () -> Void) -> ScheduledWork
    @discardableResult func every(_ interval: TimeInterval, _ work: @escaping @MainActor () -> Void) -> ScheduledWork
}

/// Cancels the work it came from; letting it go does not.
@MainActor
final class ScheduledWork {
    private var onCancel: (() -> Void)?
    private(set) var isCancelled = false
    init(onCancel: @escaping () -> Void) { self.onCancel = onCancel }
    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        onCancel?()
        onCancel = nil
    }
}

@MainActor
final class LiveScheduler: Scheduler {
    static let shared = LiveScheduler()

    var now: Date { Date() }

    func after(_ delay: TimeInterval, _ work: @escaping @MainActor () -> Void) -> ScheduledWork {
        timer(delay, repeats: false, work)
    }

    func every(_ interval: TimeInterval, _ work: @escaping @MainActor () -> Void) -> ScheduledWork {
        timer(interval, repeats: true, work)
    }

    private func timer(_ interval: TimeInterval, repeats: Bool, _ work: @escaping @MainActor () -> Void) -> ScheduledWork {
        var timer: Timer?
        let handle = ScheduledWork { timer?.invalidate() }
        // A fire already queued on the main actor when the work is cancelled does not run. The
        // handle is weak so it isn't kept alive by its own timer, and a handle nobody kept still
        // runs: only cancel() stops the work (a dropped `after` used to never fire).
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { [weak handle] _ in
            Task { @MainActor in if handle?.isCancelled != true { work() } }
        }
        if repeats { t.tolerance = Self.tolerance(every: interval) }
        timer = t
        return handle
    }

    /// The slack a repeating timer gets, so macOS can fire it alongside other wake-ups instead of
    /// waking the CPU for it alone: a tenth of the interval, as Apple's Timer documentation
    /// recommends. None of the app's repeating work needs exact timing (tab sleep and the Little
    /// Window archive pass every minute, auto-archive every 30, live folders every 15 s, the
    /// settings sync poll, the update checks, block lists and usage report every 6 hours). The
    /// test command file's 0.15 s poll, under a second, keeps none. One-shot `after` work keeps
    /// none either: some of it (a page's slow-response banner) is due when the user sees it.
    nonisolated static func tolerance(every interval: TimeInterval) -> TimeInterval {
        interval >= 1 ? interval * 0.1 : 0
    }
}
