//
//  ExtendedStringTests.swift
//  SwiftLintFrameworkTests
//
//  Created by Noah Gilmore on 4/5/20.
//

import XCTest

class ExtendedStringTests: XCTestCase {
    func testCountOccurrences() {
        XCTAssertEqual("aabbabaaba".countOccurrences(of: "a"), 6)
        XCTAssertEqual("".countOccurrences(of: "a"), 0)
        XCTAssertEqual("\n\n".countOccurrences(of: "\n"), 2)
    }
}
