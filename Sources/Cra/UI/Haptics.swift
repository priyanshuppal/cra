import AppKit

/// Every haptic Cra plays goes through here, so `cra://debug?haptics=<label>` can say how many of
/// each pattern have played: "Cra haptics <label>: generic=<n> alignment=<n> levelChange=<n>".
@MainActor
enum Haptics {
    private(set) static var counts: [String: Int] = [:]

    static func play(_ pattern: NSHapticFeedbackManager.FeedbackPattern,
                     at time: NSHapticFeedbackManager.PerformanceTime = .now) {
        counts[name(pattern), default: 0] += 1
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: time)
    }

    /// `cra://debug?haptics=reset`: count from zero, so a scenario counts only what it does next.
    static func reset() { counts = [:] }

    static var readout: String {
        ["generic", "alignment", "levelChange"].map { "\($0)=\(counts[$0] ?? 0)" }.joined(separator: " ")
    }

    private static func name(_ pattern: NSHapticFeedbackManager.FeedbackPattern) -> String {
        switch pattern {
        case .alignment: "alignment"
        case .levelChange: "levelChange"
        default: "generic"
        }
    }
}
