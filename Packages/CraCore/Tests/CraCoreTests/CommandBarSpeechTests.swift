import CraCore
import Testing

struct CommandBarSpeechTests {
    struct Row: Sendable, CustomTestStringConvertible {
        let title: String, subtitle: String, trailing: String?, index: Int, count: Int, spoken: String
        var testDescription: String { spoken }
    }

    static let rows: [Row] = [
        // An open tab: its title, address, Arc's action and where it sits.
        Row(title: "GitHub", subtitle: "github.com", trailing: "Switch to Tab", index: 1, count: 5,
            spoken: "GitHub, github.com, Switch to Tab, 2 of 5"),
        // An archived tab reads Arc's Restore.
        Row(title: "Docs", subtitle: "Archived 2 days ago", trailing: "Restore", index: 0, count: 3,
            spoken: "Docs, Archived 2 days ago, Restore, 1 of 3"),
        // A search row: no address, no action.
        Row(title: "Search Google for cats", subtitle: "", trailing: nil, index: 0, count: 1,
            spoken: "Search Google for cats, 1 of 1"),
        // Empty and blank parts are left out, not read as pauses.
        Row(title: "Example", subtitle: "  ", trailing: "", index: 4, count: 5, spoken: "Example, 5 of 5"),
        // A command reads its shortcut.
        Row(title: "New Tab", subtitle: "", trailing: "⌘T", index: 2, count: 4, spoken: "New Tab, ⌘T, 3 of 4"),
    ]

    @Test(arguments: rows)
    func rowLabel(_ r: Row) {
        #expect(CommandBarSpeech.text(title: r.title, subtitle: r.subtitle, trailing: r.trailing, index: r.index, count: r.count) == r.spoken)
    }

    @Test func completionIsAnnouncedAsAutocompleted() {
        #expect(CommandBarSpeech.completion("github.com") == "github.com, autocompleted")
    }

    typealias Shown = CommandBarSpeech.Shown

    /// The bar opening (nothing said yet) reads the selected row.
    @Test func firstShowReadsTheSelectedRow() {
        let now = Shown(selectedIndex: 0, selectedID: "a", topID: "a", completion: nil)
        #expect(CommandBarSpeech.announcement(from: nil, to: now, row: "A, 1 of 2") == "A, 1 of 2")
    }

    /// ↓ moves the selection: the new row is read.
    @Test func arrowReadsTheNewRow() {
        let before = Shown(selectedIndex: 0, selectedID: "a", topID: "a", completion: nil)
        let after = Shown(selectedIndex: 1, selectedID: "b", topID: "a", completion: nil)
        #expect(CommandBarSpeech.announcement(from: before, to: after, row: "B, 2 of 2") == "B, 2 of 2")
    }

    /// A keystroke that leaves the top row, the selection and the completion as they were says nothing:
    /// VoiceOver already echoes the letter.
    @Test func keystrokeWithTheSameTopRowIsSilent() {
        let shown = Shown(selectedIndex: 0, selectedID: "typed", topID: "typed", completion: nil)
        #expect(CommandBarSpeech.announcement(from: shown, to: shown, row: "git, 1 of 3") == nil)
    }

    /// A keystroke that brings a different row to the top reads it.
    @Test func newTopRowIsRead() {
        let before = Shown(selectedIndex: 0, selectedID: "typed", topID: "typed", completion: nil)
        let after = Shown(selectedIndex: 0, selectedID: "tab:1", topID: "tab:1", completion: nil)
        #expect(CommandBarSpeech.announcement(from: before, to: after, row: "GitHub, 1 of 3") == "GitHub, 1 of 3")
    }

    /// The field completing to a host reads the completion, not the row.
    @Test func inlineCompletionIsRead() {
        let before = Shown(selectedIndex: 0, selectedID: "typed", topID: "typed", completion: nil)
        let after = Shown(selectedIndex: 0, selectedID: "typed", topID: "typed", completion: "github.com")
        #expect(CommandBarSpeech.announcement(from: before, to: after, row: "git, 1 of 3") == "github.com, autocompleted")
        // The next letter keeps the same completion: nothing more.
        #expect(CommandBarSpeech.announcement(from: after, to: after, row: "gith, 1 of 3") == nil)
    }

    /// With a completion showing, ↓ to another row reads that row.
    @Test func arrowPastACompletionReadsTheRow() {
        let before = Shown(selectedIndex: 0, selectedID: "typed", topID: "typed", completion: "github.com")
        let after = Shown(selectedIndex: 1, selectedID: "tab:1", topID: "typed", completion: "github.com")
        #expect(CommandBarSpeech.announcement(from: before, to: after, row: "GitHub, 2 of 3") == "GitHub, 2 of 3")
    }
}
