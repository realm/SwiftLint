//
//  YamlParserTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/1/16.
//  Copyright © 2016 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

class YamlParserTests: XCTestCase {

    func testParseEmptyString() {
        XCTAssertEqual((try YamlParser.parse("")).count, 0,
                       "Parsing empty YAML string should succeed")
    }

    func testParseValidString() {
        XCTAssertEqual(try YamlParser.parse("a: 1\nb: 2").count, 2,
                       "Parsing valid YAML string should succeed")
    }

    func testParseInvalidStringThrows() {
        checkError(YamlParserError.yamlParsing("2:1: error: parser: did not find expected <document start>:\na\n^")) {
            _ = try YamlParser.parse("|\na")
        }
    }
}
