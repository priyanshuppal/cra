/// What start-up does about Cra's "Cra Safe Storage" Keychain item (SafeStorage.swift) before Chromium starts.
public enum SafeStoragePlan {
    /// Whether to search the framework binary for the item's name before moving a profile off the mock
    /// keychain. The engine's framework is built with engine/chromium/patches/keychain-service-name.patch,
    /// so the name is always there; a CEF framework may predate scripts/fetch-cef.sh's patch. The search
    /// maps the whole binary: 1.6 s cold on the engine's 256 MB framework.
    public static func scansFramework(isChromiumEngine: Bool) -> Bool { !isChromiumEngine }

    /// Whether launch reads the Keychain secret for the importer's key. A profile already on the Keychain
    /// (`markerExists`) needs it only to apply staged imported credentials; otherwise it is read when an
    /// import first asks, off the main thread. Before the marker the key is the mock keychain's, and the
    /// secret is read only by the migration itself.
    public static func readsSecretAtLaunch(markerExists: Bool, pendingImport: Bool) -> Bool {
        markerExists && pendingImport
    }
}
