import CraCore
import Testing

struct SafeStoragePlanTests {
    @Test func engineSkipsFrameworkScan() {
        #expect(!SafeStoragePlan.scansFramework(isChromiumEngine: true))
    }

    @Test func cefStillScans() {
        #expect(SafeStoragePlan.scansFramework(isChromiumEngine: false))
    }

    @Test func noKeychainReadWithoutPendingImport() {
        #expect(!SafeStoragePlan.readsSecretAtLaunch(markerExists: true, pendingImport: false))
        #expect(!SafeStoragePlan.readsSecretAtLaunch(markerExists: false, pendingImport: false))
    }

    @Test func pendingImportReadsSecret() {
        #expect(SafeStoragePlan.readsSecretAtLaunch(markerExists: true, pendingImport: true))
        // Before the migration the importer's key is the mock keychain's: nothing to read for it.
        #expect(!SafeStoragePlan.readsSecretAtLaunch(markerExists: false, pendingImport: true))
    }
}
