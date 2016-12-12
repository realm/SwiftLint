//
//  FunctionBodyLengthRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/01/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

private func funcWithBody(_ body: String) -> String {
    return "func abc() {\nvar x = 0\n\(body)}\n"
}

class FunctionBodyLengthRuleTests: XCTestCase {

    func testFunctionBodyLengths() {
        let longFunctionBody = funcWithBody(
            repeatElement("x = 0\n", count: 39).joined()
        )
        XCTAssertEqual(violations(longFunctionBody), [])

        let longerFunctionBody = funcWithBody(
            repeatElement("x = 0\n", count: 40).joined()
        )
        XCTAssertEqual(violations(longerFunctionBody), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less excluding comments and " +
            "whitespace: currently spans 41 lines")])

        let longerFunctionBodyWithEmptyLines = funcWithBody(
            "// swiftlint:disable vertical_whitespace\n" +
            repeatElement("\n", count: 100).joined()
        )
        XCTAssertEqual(violations(longerFunctionBodyWithEmptyLines), [])
    }

    func testFunctionBodyLengthsWithComments() {
        let longFunctionBodyWithComments = funcWithBody(
            repeatElement("x = 0\n", count: 39).joined() +
            "// comment only line should be ignored.\n"
        )
        XCTAssertEqual(violations(longFunctionBodyWithComments), [])

        let longerFunctionBodyWithComments = funcWithBody(
            repeatElement("x = 0\n", count: 40).joined() +
            "// comment only line should be ignored.\n"
        )
        XCTAssertEqual(violations(longerFunctionBodyWithComments), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less excluding comments and " +
            "whitespace: currently spans 41 lines")])
    }

    func testFunctionBodyLengthsWithMultilineComments() {
        let longFunctionBodyWithMultilineComments = funcWithBody(
            repeatElement("x = 0\n", count: 39).joined() +
            "/* multi line comment only line should be ignored.\n*/\n"
        )
        XCTAssertEqual(violations(longFunctionBodyWithMultilineComments), [])

        let longerFunctionBodyWithMultilineComments = funcWithBody(
            repeatElement("x = 0\n", count: 40).joined() +
            "/* multi line comment only line should be ignored.\n*/\n"
        )
        XCTAssertEqual(violations(longerFunctionBodyWithMultilineComments), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less excluding comments and " +
            "whitespace: currently spans 41 lines")])
    }

    private func violations(_ string: String) -> [StyleViolation] {
        let config = makeConfig(nil, FunctionBodyLengthRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(string, config: config)
    }
}

extension FunctionBodyLengthRuleTests {
    // swiftlint:disable:next void_return
    static var allTests: [(String, (FunctionBodyLengthRuleTests) -> () throws -> Void)] {
        return [
            ("testFunctionBodyLengths",
                testFunctionBodyLengths),
            ("testFunctionBodyLengthsWithComments",
                testFunctionBodyLengthsWithComments),
            ("testFunctionBodyLengthsWithMultilineComments",
                testFunctionBodyLengthsWithMultilineComments)
        ]
    }
}
