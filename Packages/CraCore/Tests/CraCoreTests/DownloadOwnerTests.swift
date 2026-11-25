import CraCore
import Foundation
import Testing

/// Which profile a finished download is saved under: the page's, not the browser window's.
struct DownloadOwnerTests {
    static let tab = UUID(uuidString: "C0000000-0000-0000-0000-000000000001")!
    static let hobbies = UUID(uuidString: "B0000000-0000-0000-0000-000000000001")!

    static func tabProfile(_ id: UUID) -> String { id == tab ? "Profile Work" : "Default" }
    static func directory(_ id: UUID?) -> String { id.map { "Profile \($0.uuidString)" } ?? "Default" }

    static let cases: [(DownloadOwner.Source?, String)] = [
        // A tab: its own profile.
        (.tab(tab), "Profile Work"),
        // A Little Window on Hobbies: Hobbies. Cra saved it under the browser window's Work.
        (.littleWindow(profileID: hobbies), "Profile B0000000-0000-0000-0000-000000000001"),
        // A Little Window on Default: Default, not the browser window's profile.
        (.littleWindow(profileID: nil), "Default"),
        // No source (an extension's download): the browser window's.
        (nil, "Profile Work"),
    ]

    /// The browser window shows a Work-profile space.
    @Test(arguments: cases)
    func savedUnderThePagesProfile(source: DownloadOwner.Source?, expected: String) {
        let profile = DownloadOwner.profile(source: source, mainProfile: "Profile Work",
                                            tabProfile: Self.tabProfile, directory: Self.directory)
        #expect(profile == expected)
    }
}
