import AppKit
import CraCEF

/// One Chromium page made ahead, for the profile that made a page last, which the next tab that
/// needs a page takes (SparePage in CraCore): the ~34 ms CEF spends making a page's window then
/// falls between clicks, not on one. Shared by every window's BrowserManager. A spare has no
/// delegate and no tab; its window stays hidden and extensions don't see it (Cra.setSpare) until a
/// tab takes it. None is kept while the Mac is short of memory (SparePage.keeps(pressure:)).
@MainActor
final class SparePages {
    static let shared = SparePages()

    /// CRA_SPARE_PAGES=0 turns spares off (for measuring and for a CEF without Cra.setSpare).
    static let isEnabled = ProcessInfo.processInfo.environment["CRA_SPARE_PAGES"] != "0"

    /// Whether a spare may be made now, asked just before one is: SparePage.keeps(pressure:) on
    /// macOS's memory pressure, which the app sets at launch; tests set their own.
    var mayMake: () -> Bool = { true }

    private var spares: [String: CraBrowser] = [:]
    private var pending: [String: ScheduledWork] = [:]

    /// A spare for `profilePath` that Chromium has finished making, or nil. It is no longer kept.
    func take(profilePath: String?) -> CraBrowser? {
        let key = SparePage.key(profilePath: profilePath)
        guard Self.isEnabled, let b = spares[key] else { return nil }
        guard b.isCreated, !b.isClosed else { return nil }
        spares[key] = nil
        return b
    }

    /// Makes `profilePath`'s next spare `SparePage.refillDelay` from now, unless it has one or the
    /// Mac is short of memory then. Another profile's spare goes: only the profile used last keeps one.
    func refill(profilePath: String?, frame: NSRect, clock: Scheduler) {
        let key = SparePage.key(profilePath: profilePath)
        guard Self.isEnabled, CraCEFRuntime.supportsSparePages(), spares[key] == nil, pending[key] == nil else { return }
        for other in SparePage.dropped(making: key, kept: Set(spares.keys).union(pending.keys)) { drop(key: other) }
        pending[key] = clock.after(SparePage.refillDelay) { [weak self] in
            guard let self else { return }
            self.pending[key] = nil
            if let old = self.spares[key], !old.isClosed { return }
            guard self.mayMake() else { return }
            self.spares[key] = CraBrowser(spareWithFrame: frame, profilePath: profilePath)
        }
    }

    /// Every spare and every pending refill goes (memory pressure; tests start from none). Returns
    /// how many spares were closed.
    @discardableResult
    func dropAll() -> Int {
        for w in pending.values { w.cancel() }
        pending = [:]
        let closed = spares.count
        for b in spares.values { b.close() }
        spares = [:]
        return closed
    }

    /// A profile was deleted: its spare goes too.
    func drop(profilePath: String?) {
        drop(key: SparePage.key(profilePath: profilePath))
    }

    private func drop(key: String) {
        pending.removeValue(forKey: key)?.cancel()
        spares.removeValue(forKey: key)?.close()
    }
}
