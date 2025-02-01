import SourceKittenFramework
import Testing

@Suite
struct StringViewExtensionTests {
    @Test
    func byteOffsetInvalidCases() {
        let view = StringView("")

        #expect(view.byteOffset(forLine: 0, bytePosition: 1) == nil)
        #expect(view.byteOffset(forLine: 1, bytePosition: 0) == nil)
        #expect(view.byteOffset(forLine: -10, bytePosition: 1) == nil)
        #expect(view.byteOffset(forLine: 0, bytePosition: -11) == nil)
        #expect(view.byteOffset(forLine: 2, bytePosition: 1) == nil)
    }

    @Test
    func byteOffsetFromLineAndBytePosition() {
        #expect(StringView("").byteOffset(forLine: 1, bytePosition: 1) == 0)
        #expect(StringView("a").byteOffset(forLine: 1, bytePosition: 1) == 0)
        #expect(StringView("aaa").byteOffset(forLine: 1, bytePosition: 3) == 2)
        #expect(StringView("a🍰a").byteOffset(forLine: 1, bytePosition: 6) == 5)
        #expect(StringView("a🍰a\na").byteOffset(forLine: 2, bytePosition: 1) == 7)
    }
}
