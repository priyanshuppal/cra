import CraCore
import Testing

/// The copy a release launch hands over to (NewestCopy.openNewerInstalledCopy).
struct NewestCopyChoiceTests {
    let teams = ["/Applications/Cra.app": "TEAM", "/Users/me/Downloads/Cra.app": "TEAM",
                 "/Users/me/Apps/Cra.app": "TEAM", "/Users/me/Other/Cra.app": "OTHER"]

    func choose(_ current: String, _ candidates: [(id: String, version: String)],
                ownTeam: String? = "TEAM") -> String? {
        NewestCopyChoice.newer(current: current, candidates: candidates,
                               ownTeam: { ownTeam }, teamOf: { teams[$0] })?.id
    }

    @Test func ownTeamIsNotReadWithoutANewerCopy() {
        var ownReads = 0, candidateReads = 0
        for candidates: [(id: String, version: String)] in [[], [("/Users/me/Apps/Cra.app", "0.1.9")],
                                                            [("/Users/me/Apps/Cra.app", "0.1.10")]] {
            let chosen = NewestCopyChoice.newer(current: "0.1.10", candidates: candidates,
                                                ownTeam: { ownReads += 1; return "TEAM" },
                                                teamOf: { _ in candidateReads += 1; return "TEAM" })
            #expect(chosen == nil)
        }
        #expect(ownReads == 0)
        #expect(candidateReads == 0)
        // A newer copy reads both.
        _ = NewestCopyChoice.newer(current: "0.1.10", candidates: [("/Users/me/Apps/Cra.app", "0.1.11")],
                                   ownTeam: { ownReads += 1; return "TEAM" },
                                   teamOf: { _ in candidateReads += 1; return "TEAM" })
        #expect(ownReads == 1)
        #expect(candidateReads == 1)
    }

    @Test func opensTheNewestSameTeamCopy() {
        #expect(choose("0.1.9", [("/Users/me/Downloads/Cra.app", "0.1.10")]) == "/Users/me/Downloads/Cra.app")
        // 0.1.12 is newer than 0.1.9 numerically, and the newest wins.
        #expect(choose("0.1.8", [("/Users/me/Downloads/Cra.app", "0.1.9"), ("/Users/me/Apps/Cra.app", "0.1.12"),
                                 ("/Applications/Cra.app", "0.1.10")]) == "/Users/me/Apps/Cra.app")
        // A dev build is older than any release.
        #expect(choose("0.0.0-dev", [("/Applications/Cra.app", "0.1.1")]) == "/Applications/Cra.app")
    }

    @Test func ignoresOtherTeam() {
        // The newest copy is someone else's: the newest of ours instead.
        #expect(choose("0.1.1", [("/Users/me/Other/Cra.app", "0.9.0"), ("/Users/me/Apps/Cra.app", "0.1.2")])
                == "/Users/me/Apps/Cra.app")
        #expect(choose("0.1.1", [("/Users/me/Other/Cra.app", "0.9.0")]) == nil)
        // Unsigned candidates and an unsigned self take no part.
        #expect(choose("0.1.1", [("/unsigned/Cra.app", "0.9.0")]) == nil)
        #expect(choose("0.1.1", [("/Applications/Cra.app", "0.9.0")], ownTeam: nil) == nil)
    }

    @Test func ignoresOlderAndSameVersion() {
        #expect(choose("0.1.10", [("/Applications/Cra.app", "0.1.9"), ("/Users/me/Apps/Cra.app", "0.1.10")]) == nil)
        #expect(NewestCopyChoice.isOlder("0.1.9", than: "0.1.10"))
        #expect(!NewestCopyChoice.isOlder("0.1.10", than: "0.1.10"))
    }
}
