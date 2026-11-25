/// What VoiceOver reads after a sidebar row's title. The rows gave only their title, so VoiceOver couldn't tell
/// which tab was open, which were pinned, which played sound or were muted. The words follow Cra's own: the
/// speaker button's "Mute Tab" / "Unmute Tab", the Pinned section, the unread dot.
public enum SidebarRowAccessibility {
    /// "selected, pinned, playing audio"; empty for a plain row. `muted` wins over `audible`, as the speaker
    /// shows. `unread` is read only where the dot shows, on a row that isn't selected.
    public static func value(selected: Bool, pinned: Bool = false, audible: Bool = false, muted: Bool = false,
                             unread: Bool = false) -> String {
        var parts: [String] = []
        if selected { parts.append("selected") }
        if pinned { parts.append("pinned") }
        if muted { parts.append("muted") } else if audible { parts.append("playing audio") }
        if unread && !selected { parts.append("unread") }
        return parts.joined(separator: ", ")
    }
}
