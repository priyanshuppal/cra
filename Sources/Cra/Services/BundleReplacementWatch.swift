import Foundation

/// Calls `changed` a moment after Cra.app is replaced or rewritten on disk, instead of reading its
/// Info.plist every 30 s. It watches every node a replacement touches:
/// - the folder holding the bundle, for a new Cra.app moved in after the old one went (`brew upgrade
///   --greedy`, a copy dragged over it in Finder, scenario.sh's replace-app);
/// - the bundle and its Contents folder, for a bundle removed, renamed or with entries swapped;
/// - Contents/Info.plist itself, for a copy written into the existing bundle (scripts/build.sh
///   rsyncs build/Cra.app in place so the folder keeps its identity; rsync renames each file over
///   the old one, and a plain copy writes it in place).
/// Each change re-arms the watches on whatever is at those paths now. Sparkle never replaces a
/// running Cra: its installer waits for Cra to quit.
@MainActor
final class BundleReplacementWatch {
    private let bundle: URL
    private let clock: Scheduler
    private let settle: TimeInterval
    private let changed: @MainActor () -> Void
    private var sources: [DispatchSourceFileSystemObject] = []
    private var pending: ScheduledWork?

    /// `settle`: a replacement writes many files; one call after the last of them.
    init(bundle: URL, clock: Scheduler, settle: TimeInterval = 1, changed: @escaping @MainActor () -> Void) {
        self.bundle = bundle
        self.clock = clock
        self.settle = settle
        self.changed = changed
        arm()
    }

    func cancel() {
        pending?.cancel()
        sources.forEach { $0.cancel() }
        sources = []
    }

    private func arm() {
        sources.forEach { $0.cancel() }
        let contents = bundle.appendingPathComponent("Contents")
        sources = [
            watch(bundle.deletingLastPathComponent(), [.write]),
            watch(bundle, [.write, .delete, .rename]),
            watch(contents, [.write, .delete, .rename]),
            watch(contents.appendingPathComponent("Info.plist"), [.write, .extend, .delete, .rename]),
        ].compactMap { $0 }
    }

    private func watch(_ url: URL, _ events: DispatchSource.FileSystemEvent) -> DispatchSourceFileSystemObject? {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return nil }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: events, queue: .main)
        source.setEventHandler { [weak self] in MainActor.assumeIsolated { self?.fired() } }
        source.setCancelHandler { close(fd) }
        source.resume()
        return source
    }

    private func fired() {
        pending?.cancel()
        pending = clock.after(settle) { [weak self] in
            guard let self else { return }
            arm()
            changed()
        }
    }
}
