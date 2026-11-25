import Foundation

/// The profile a finished download is recorded under in downloads.json.
///
/// A download comes from a browser window's tab, or from a Little Window or Peek, whose page loads
/// in its own profile (`LittleWindowState.profileID`, nil for Default). Downloads from a Little
/// Window used to go through the browser window with no source, so they were saved under the
/// browser window's profile.
public enum DownloadOwner {
    public enum Source: Equatable, Sendable {
        /// A tab in a browser window.
        case tab(UUID)
        /// A Little Window or a Peek, in its profile (nil: Default).
        case littleWindow(profileID: UUID?)
    }

    /// The source's profile directory; the browser window's (`mainProfile`) when the source isn't known.
    /// `tabProfile` names a tab's profile directory, `directory` a profile's (nil: Default).
    public static func profile(source: Source?, mainProfile: String,
                               tabProfile: (UUID) -> String, directory: (UUID?) -> String) -> String {
        switch source {
        case .tab(let id): tabProfile(id)
        case .littleWindow(let profileID): directory(profileID)
        case nil: mainProfile
        }
    }
}
