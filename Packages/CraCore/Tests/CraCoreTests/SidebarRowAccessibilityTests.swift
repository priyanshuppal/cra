import CraCore
import Testing

struct SidebarRowAccessibilityTests {
    struct Row: Sendable, CustomTestStringConvertible {
        var selected = false, pinned = false, audible = false, muted = false, unread = false
        let value: String
        var testDescription: String { value.isEmpty ? "plain" : value }
    }

    static let rows: [Row] = [
        Row(value: ""),
        Row(selected: true, value: "selected"),
        Row(pinned: true, value: "pinned"),
        Row(selected: true, pinned: true, value: "selected, pinned"),
        Row(audible: true, value: "playing audio"),
        Row(selected: true, audible: true, value: "selected, playing audio"),
        // A muted tab reads muted whether or not its page plays, as its speaker shows.
        Row(muted: true, value: "muted"),
        Row(audible: true, muted: true, value: "muted"),
        Row(unread: true, value: "unread"),
        // The unread dot isn't drawn on the selected tab, so it isn't read there either.
        Row(selected: true, unread: true, value: "selected"),
        Row(selected: false, pinned: true, audible: true, unread: true, value: "pinned, playing audio, unread"),
    ]

    @Test(arguments: rows)
    func value(_ r: Row) {
        #expect(SidebarRowAccessibility.value(selected: r.selected, pinned: r.pinned, audible: r.audible, muted: r.muted, unread: r.unread) == r.value)
    }
}
