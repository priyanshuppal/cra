import CraCore
import Testing

struct CloseItemsToastTests {
    @Test(arguments: [
        (CloseItemsToast.Kind.clear, 1, "Cleared Tabs! Use"),
        (.clear, 12, "Cleared Tabs! Use"),
        (.deleteFolder, 1, "Folder deleted! Use"),
        (.deleteFolder, 3, "Folders deleted! Use"),
    ])
    func arcsWordsWithTheUndoKeys(kind: CloseItemsToast.Kind, count: Int, text: String) {
        let toast = CloseItemsToast.text(kind: kind, count: count)
        #expect(toast.text == text)
        #expect(toast.keyCap?.keys == "⌘Z" && toast.keyCap?.after == "to undo.")
    }
}
