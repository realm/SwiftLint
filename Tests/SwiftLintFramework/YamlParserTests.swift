//
//  YamlParserTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/1/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import XCTest
@testable import SwiftLintFramework

class YamlParserTests: XCTestCase {

    // swiftlint:disable force_try
    func testParseEmptyString() {
        XCTAssertEqual((try! YamlParser.parse("")).count, 0,
                        "Parsing empty YAML string should succeed")
    }

    func testParseValidString() {
        XCTAssertEqual(try! YamlParser.parse("a: 1\nb: 2").count, 2,
                        "Parsing valid YAML string should succeed")
    }

    func testParseInvalidStringThrows() {
        checkError(YamlParserError.YamlParsing("expected end, near \"a\"")) {
            try YamlParser.parse("|\na")
        }
    }
    // swiftlint:enable force_try
}
