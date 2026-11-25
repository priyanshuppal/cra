/// Whether a held key's repeat still runs its command. macOS sends a repeat every
/// `NSEvent.keyRepeatInterval` (about 33 ms at the fastest setting), and a tab or space switch can
/// hold the main thread for 30–100 ms or more, so repeats of Next Tab queue behind slow switches
/// and play out after the key is let go: the selection walks on for several tabs, loading each.
/// A repeat whose event is older than one and a half intervals waited behind earlier work and is
/// dropped; a first press always runs, and a repeat that arrives on time runs, so a held key still
/// walks the list as fast as the switches keep up.
public enum KeyRepeatGate {
    /// The commands a held key repeats that the gate applies to (KeyBindings' ids).
    public static let actions: Set<String> = ["nextTab", "previousTab", "nextSpace", "previousSpace"]

    /// How many repeat intervals old a repeat may be and still run.
    public static let staleAfter = 1.5

    /// `eventTime` and `now` are on the same clock: an NSEvent's timestamp and the system uptime.
    public static func accepts(isRepeat: Bool, eventTime: Double, now: Double, repeatInterval: Double) -> Bool {
        guard isRepeat else { return true }
        return now - eventTime <= staleAfter * repeatInterval
    }
}
