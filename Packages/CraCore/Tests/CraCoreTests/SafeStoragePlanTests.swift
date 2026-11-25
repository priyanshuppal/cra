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

    /// Chromium made the item between Cra's read and its add: Cra uses Chromium's secret, not no secret.
    @Test(arguments: [
        (SafeStoragePlan.KeychainAdd.added, SafeStoragePlan.SecretAfterAdd.own),
        (.duplicate, .readAgain),
        (.failed, .noSecret),
    ])
    func duplicateAddReadsTheWinnersSecret(add: SafeStoragePlan.KeychainAdd, then: SafeStoragePlan.SecretAfterAdd) {
        #expect(SafeStoragePlan.secretAfter(add) == then)
    }
}
