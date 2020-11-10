import XCTest

class ExtendedStringTests: XCTestCase {
    func testCountOccurrences() {
        XCTAssertEqual("aabbabaaba".countOccurrences(of: "a"), 6)
        XCTAssertEqual("".countOccurrences(of: "a"), 0)
        XCTAssertEqual("\n\n".countOccurrences(of: "\n"), 2)
    }

    func testComponentsSeparatedByCamelCase() {
        XCTAssertEqual(
            "camelCaseString".componentsSeparatedByCamelCase,
            ["camel", "Case", "String"]
        )
        XCTAssertEqual(
            "one".componentsSeparatedByCamelCase,
            ["one"]
        )
        XCTAssertEqual(
            "acronymAtEndABC".componentsSeparatedByCamelCase,
            ["acronym", "At", "End", "ABC"]
        )
        XCTAssertEqual(
            "acronymABCInMiddle".componentsSeparatedByCamelCase,
            ["acronym", "ABC", "In", "Middle"]
        )
        XCTAssertEqual(
            "CapitalAtStart".componentsSeparatedByCamelCase,
            ["Capital", "At", "Start"]
        )
        XCTAssertEqual(
            "stringWithASingleLetterWord".componentsSeparatedByCamelCase,
            ["string", "With", "A", "Single", "Letter", "Word"]
        )
        XCTAssertEqual("".componentsSeparatedByCamelCase, [])
    }
}
