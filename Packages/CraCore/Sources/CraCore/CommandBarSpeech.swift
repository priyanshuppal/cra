import Foundation

/// What VoiceOver says for the command bar's rows. The rows had no accessibility of their own, so ⌘T, typing
/// and ↓ read only the field's text and nothing about what Return would open.
public enum CommandBarSpeech {
    /// A row's label: "GitHub, github.com, Switch to Tab, 2 of 5". Empty parts are left out; `trailing` is the
    /// action the row's end shows ("Switch to Tab", "Restore", a command's shortcut). `index` counts from 0.
    public static func text(title: String, subtitle: String, trailing: String?, index: Int, count: Int) -> String {
        let parts = [title, subtitle, trailing ?? ""].map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return (parts + ["\(index + 1) of \(count)"]).joined(separator: ", ")
    }

    /// The grey text the field completes to, as VoiceOver announces it.
    public static func completion(_ text: String) -> String { "\(text), autocompleted" }

    /// What the bar showed when it last spoke: a new line is announced only when one of these changes, so a
    /// keystroke that leaves the selected row, the top row and the completion as they were says nothing more
    /// than the field's own echo.
    public struct Shown: Equatable, Sendable {
        public var selectedIndex: Int
        public var selectedID: String?
        public var topID: String?
        public var completion: String?
        public init(selectedIndex: Int, selectedID: String?, topID: String?, completion: String?) {
            self.selectedIndex = selectedIndex
            self.selectedID = selectedID
            self.topID = topID
            self.completion = completion
        }
    }

    /// The line to announce when the bar goes from `last` to `now`, nil when nothing VoiceOver should say
    /// changed. `row` is the selected row's label. The typed row with a completion reads the completion.
    public static func announcement(from last: Shown?, to now: Shown, row: String?) -> String? {
        guard now != last else { return nil }
        if now.selectedIndex == 0, let c = now.completion, !c.isEmpty { return completion(c) }
        return row
    }
}
