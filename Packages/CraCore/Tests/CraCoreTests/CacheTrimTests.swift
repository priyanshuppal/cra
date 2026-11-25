import Testing
@testable import CraCore

struct CacheTrimTests {
    struct Case: Sendable, CustomTestStringConvertible {
        var name: String
        var cached: [String]
        var keeping: Set<String>
        var survivors: Set<String>
        var testDescription: String { name }
    }

    static let tab = "github.com#tab-6f1c", icon = "console.aws.amazon.com#9a2b"

    static let cases: [Case] = [
        Case(name: "nothing cached", cached: [], keeping: [tab], survivors: []),
        Case(name: "nothing shown drops everything", cached: ["example.com", tab], keeping: [], survivors: []),
        Case(name: "a shown key stays, history's hosts go", cached: [tab, "news.example", "docs.example"], keeping: [tab], survivors: [tab]),
        Case(name: "a tab's site key stays with it", cached: [tab, "github.com", "gitlab.com"], keeping: [tab], survivors: [tab, "github.com"]),
        Case(name: "an icon-URL key's site too", cached: [icon, "console.aws.amazon.com"], keeping: [icon], survivors: [icon, "console.aws.amazon.com"]),
        Case(name: "another tab on the same site goes", cached: ["github.com#tab-0000"], keeping: [tab], survivors: []),
        Case(name: "a custom icon shown stays", cached: ["custom-1", "custom-2"], keeping: ["custom-1"], survivors: ["custom-1"]),
        Case(name: "a kept key not cached isn't made up", cached: ["a.example"], keeping: ["b.example"], survivors: []),
    ]

    @Test(arguments: cases)
    func survivors(_ c: Case) {
        #expect(CacheTrim.survivors(cached: c.cached, keeping: c.keeping) == c.survivors)
    }

    @Test(arguments: [
        (nil, .warning, true), (nil, .critical, true), (nil, .normal, false), (nil, .unknown, false),
        (.normal, .warning, true), (.unknown, .critical, true),
        (.warning, .warning, false), (.warning, .critical, false), (.critical, .warning, false),
        (.warning, .normal, false), (.critical, .normal, false),
    ] as [(PerfSystemSample.Pressure?, PerfSystemSample.Pressure, Bool)])
    func trimsAsMemoryRunsShort(previous: PerfSystemSample.Pressure?, pressure: PerfSystemSample.Pressure, trims: Bool) {
        #expect(CacheTrim.trims(from: previous, to: pressure) == trims)
    }
}
