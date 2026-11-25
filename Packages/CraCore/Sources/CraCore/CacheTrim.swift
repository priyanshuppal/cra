import Foundation

/// What FaviconCache keeps in memory when the Mac runs short of it. Every host ever shown stays
/// otherwise (the command bar's history among them), and only an import cleared it.
public enum CacheTrim {
    /// The cached keys that stay: the ones a row shows (the sidebar, favorites, open windows), and the
    /// site keys those fall back to while a tab has no icon of its own. The rest read their file again
    /// when asked.
    public static func survivors(cached: some Sequence<String>, keeping: Set<String>) -> Set<String> {
        let sites = Set(keeping.map(FaviconKey.siteKey(of:)))
        return Set(cached.filter { keeping.contains($0) || sites.contains($0) })
    }

    /// Trim once as memory runs short, not on every pass while it stays short.
    public static func trims(from previous: PerfSystemSample.Pressure?, to pressure: PerfSystemSample.Pressure) -> Bool {
        short(pressure) && !(previous.map(short) ?? false)
    }

    /// PerfSystemSample.Pressure.isShort, spelled out so the harnesses that build FaviconCache from single
    /// files need this one and Perf, not TabSleepPolicy.
    private static func short(_ pressure: PerfSystemSample.Pressure) -> Bool { pressure == .warning || pressure == .critical }
}
