import XCTest

class ExtendedStringTests: SwiftLintTestCase {
    func testCountOccurrences() {
        XCTAssertEqual("aabbabaaba".countOccurrences(of: "a"), 6)
        XCTAssertEqual("".countOccurrences(of: "a"), 0)
        XCTAssertEqual("\n\n".countOccurrences(of: "\n"), 2)
    }
}
