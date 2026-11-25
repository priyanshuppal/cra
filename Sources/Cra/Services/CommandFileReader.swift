import Foundation

/// Testing aid behind CRA_COMMAND_FILE: hands each complete line appended to the file to `onLine`,
/// once and in order. It watches the file instead of polling it, so an idle test copy wakes no more
/// than users' Cra (the 0.15 s poll it replaced was ~6.7 wakeups/s in every bench idle row). A file
/// that is truncated starts again from its beginning; one that is deleted or replaced is read to its
/// end and the new one at the path is followed. Only while no file can be opened at the path does it
/// look again every 0.15 s.
@MainActor
final class CommandFileReader {
    private let path: String
    private let clock: Scheduler
    private let onLine: @MainActor (String) -> Void
    private var fd: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private var retry: ScheduledWork?
    /// Counts the files opened, so a change queued for a file already left doesn't reopen the next one.
    private var opened = 0
    private var offset: UInt64 = 0
    /// The bytes after the last newline: a line written in more than one write.
    private var pending = Data()

    init(path: String, clock: Scheduler, onLine: @escaping @MainActor (String) -> Void) {
        self.path = path
        self.clock = clock
        self.onLine = onLine
        if !openFile() { retryOpening() }
    }

    func cancel() {
        retry?.cancel()
        retry = nil
        closeFile()
    }

    private func openFile() -> Bool {
        let fd = open(path, O_RDONLY | O_CLOEXEC)
        guard fd >= 0 else { return false }
        self.fd = fd
        opened += 1
        offset = 0
        pending.removeAll()
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.write, .extend, .attrib, .delete, .rename],
                                                               queue: .main)
        let file = opened
        source.setEventHandler { [weak self, weak source] in
            let replaced = source.map { !$0.data.isDisjoint(with: [.delete, .rename]) } ?? false
            MainActor.assumeIsolated { self?.changeSoon(file, replaced: replaced) }
        }
        source.setCancelHandler { close(fd) }
        self.source = source
        source.resume()
        readAvailable()
        return true
    }

    private func closeFile() {
        source?.cancel()
        source = nil
        fd = -1
    }

    /// Lines run where the old poll's timer did, in the default run loop mode: not inside a modal
    /// panel's or a menu's tracking loop, which a command would reenter.
    private func changeSoon(_ file: Int, replaced: Bool) {
        RunLoop.main.perform(inModes: [.default]) { [weak self] in
            MainActor.assumeIsolated { self?.changed(file, replaced: replaced) }
        }
    }

    private func changed(_ file: Int, replaced: Bool) {
        guard fd >= 0, file == opened else { return }
        readAvailable()
        guard replaced else { return }
        // The old file is read to its end above (its descriptor still reads it), then the path's new one.
        closeFile()
        if !openFile() { retryOpening() }
    }

    private func retryOpening() {
        guard retry == nil else { return }
        retry = clock.every(0.15) { [weak self] in
            guard let self, self.fd < 0, self.openFile() else { return }
            self.retry?.cancel()
            self.retry = nil
        }
    }

    private func readAvailable() {
        guard fd >= 0 else { return }
        var info = stat()
        guard fstat(fd, &info) == 0 else { return }
        let size = UInt64(info.st_size)
        if size < offset {
            // Truncated: what is there now was written after it.
            offset = 0
            pending.removeAll()
        }
        guard size > offset else { return }
        var bytes = [UInt8](repeating: 0, count: Int(size - offset))
        let n = bytes.withUnsafeMutableBytes { pread(fd, $0.baseAddress, $0.count, off_t(offset)) }
        guard n > 0 else { return }
        offset += UInt64(n)
        pending.append(contentsOf: bytes[0..<n])
        guard let last = pending.lastIndex(of: 0x0A) else { return }
        // Every complete line is taken before any runs, so a line that reads the file again (or spins a
        // run loop) doesn't see these a second time.
        let complete = pending[pending.startIndex..<last]
        pending = Data(pending[(last + 1)...])
        for line in complete.split(separator: 0x0A, omittingEmptySubsequences: true) {
            onLine(String(decoding: line, as: UTF8.self))
        }
    }
}
