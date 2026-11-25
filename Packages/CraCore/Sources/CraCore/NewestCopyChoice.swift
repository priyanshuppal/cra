import Foundation

/// Which installed copy of Cra a launch hands over to, if any (see the app's `NewestCopy`).
/// Only a newer copy signed by the same team counts, so a copy from someone else is never
/// opened. Reading a team costs a code-signature check (hundreds of milliseconds for our own
/// 38 MB binary on a cold launch), so the teams are read only once a newer copy is left; in
/// the usual launch there is none and neither closure runs.
public enum NewestCopyChoice {
    /// Numeric, so 0.1.10 is newer than 0.1.9 and 0.0.0-dev is older than any release.
    public static func isOlder(_ a: String, than b: String) -> Bool {
        a.compare(b, options: .numeric) == .orderedAscending
    }

    /// - Parameters:
    ///   - current: this copy's version.
    ///   - candidates: the other installed copies and their versions.
    ///   - ownTeam: this copy's signing team, nil when unsigned or ad hoc.
    ///   - teamOf: a candidate's signing team, nil when unsigned or ad hoc.
    /// - Returns: the newest candidate newer than `current` signed by our team.
    public static func newer<ID>(current: String, candidates: [(id: ID, version: String)],
                                 ownTeam: () -> String?, teamOf: (ID) -> String?) -> (id: ID, version: String)? {
        let newer = candidates.filter { isOlder(current, than: $0.version) }
        guard !newer.isEmpty, let team = ownTeam() else { return nil }
        return newer.filter { teamOf($0.id) == team }.max { isOlder($0.version, than: $1.version) }
    }
}
