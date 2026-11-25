import Testing
@testable import CraCore

struct GlyphToneTests {
    /// A 32 × 32 icon: `runs` of (count, premultiplied RGBA) from the first pixel, the rest transparent.
    private static func icon(_ runs: [(Int, [UInt8])]) -> [UInt8] {
        var pixels: [UInt8] = []
        for (count, rgba) in runs { for _ in 0..<count { pixels += rgba } }
        return pixels + [UInt8](repeating: 0, count: GlyphTone.side * GlyphTone.side * 4 - pixels.count)
    }

    static let black: [UInt8] = [0, 0, 0, 255], white: [UInt8] = [255, 255, 255, 255], red: [UInt8] = [255, 0, 0, 255]
    static func gray(_ v: UInt8) -> [UInt8] { [v, v, v, 255] }

    struct Case: Sendable, CustomTestStringConvertible {
        var name: String
        var runs: [(Int, [UInt8])]
        var dark: Bool?
        var testDescription: String { name }
    }

    static let cases: [Case] = [
        Case(name: "nothing visible", runs: [], dark: nil),
        Case(name: "a black glyph", runs: [(100, black)], dark: true),
        Case(name: "a white glyph", runs: [(100, white)], dark: false),
        Case(name: "a mid-gray glyph", runs: [(100, gray(128))], dark: nil),
        Case(name: "a red glyph", runs: [(100, red)], dark: nil),
        Case(name: "20 visible pixels are too few", runs: [(20, black)], dark: nil),
        Case(name: "21 are enough", runs: [(21, black)], dark: true),
        Case(name: "869 of 1024 visible is see-through enough", runs: [(869, black)], dark: true),
        Case(name: "870 of 1024 (85 %) is a filled icon", runs: [(870, black)], dark: nil),
        Case(name: "a full tile", runs: [(1024, black)], dark: nil),
        Case(name: "93 % dark", runs: [(93, black), (7, red)], dark: true),
        Case(name: "92 % dark is not over 92 %", runs: [(92, black), (8, red)], dark: nil),
        Case(name: "93 % light", runs: [(93, white), (7, red)], dark: false),
        Case(name: "luminance just under 0.3 is dark", runs: [(100, gray(76))], dark: true),
        Case(name: "luminance just over 0.3 is neither", runs: [(100, gray(77))], dark: nil),
        Case(name: "luminance just over 0.75 is light", runs: [(100, gray(192))], dark: false),
        Case(name: "luminance just under 0.75 is neither", runs: [(100, gray(191))], dark: nil),
        Case(name: "premultiplied: half-covered black is still black", runs: [(100, [0, 0, 0, 200])], dark: true),
        Case(name: "premultiplied: half-covered white is still white", runs: [(100, [200, 200, 200, 200])], dark: false),
        Case(name: "alpha 128 is not visible", runs: [(100, [0, 0, 0, 128])], dark: nil),
        Case(name: "a gray tinted 0.15 or more is a colour", runs: [(100, [0, 39, 0, 255])], dark: nil),
    ]

    @Test(arguments: cases)
    func tone(_ c: Case) {
        #expect(GlyphTone.isDark(rgba: Self.icon(c.runs), width: GlyphTone.side, height: GlyphTone.side) == c.dark)
    }

    @Test func aBufferOfTheWrongSizeHasNoTone() {
        #expect(GlyphTone.isDark(rgba: Self.icon([(100, Self.black)]), width: 16, height: 16) == nil)
        #expect(GlyphTone.isDark(rgba: [], width: 0, height: 0) == nil)
    }
}
