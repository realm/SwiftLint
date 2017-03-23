//
//  FunctionBodyLengthRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/01/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

private func funcWithBody(_ body: String, violates: Bool = false) -> String {
    let marker = violates ? "↓" : ""
    return "func \(marker)abc() {\nvar x = 0\n\(body)}\n"
}

private func violatingFuncWithBody(_ body: String) -> String {
    return funcWithBody(body, violates: true)
}

class FunctionBodyLengthRuleTests: XCTestCase {

    func testFunctionBodyLengths() {
        let longFunctionBody = funcWithBody(repeatElement("x = 0\n", count: 39).joined())
        XCTAssertEqual(violations(longFunctionBody), [])

        let longerFunctionBody = violatingFuncWithBody(repeatElement("x = 0\n", count: 40).joined())
        XCTAssertEqual(violations(longerFunctionBody), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less excluding comments and " +
            "whitespace: currently spans 41 lines")])

        let longerFunctionBodyWithEmptyLines = funcWithBody(
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

        let longerFunctionBodyWithComments = violatingFuncWithBody(
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

        let longerFunctionBodyWithMultilineComments = violatingFuncWithBody(
            repeatElement("x = 0\n", count: 40).joined() +
            "/* multi line comment only line should be ignored.\n*/\n"
        )
        XCTAssertEqual(violations(longerFunctionBodyWithMultilineComments), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less excluding comments and " +
            "whitespace: currently spans 41 lines")])
    }

    func testFunctionBodyLengthsWithExcludedPatterns() {
        let longerFunctionBody = funcWithBody(repeatElement("x = 0\n", count: 40).joined())

        let config1 = makeConfig(["warning": 40, "error": 100, "excluded": ["abc"]],
                                FunctionBodyLengthRule.description.identifier)!
        XCTAssertEqual(SwiftLintFrameworkTests.violations(longerFunctionBody, config: config1), [])

        let config2 = makeConfig(["warning": 40, "error": 100, "excluded": ["abcd"]],
                                FunctionBodyLengthRule.description.identifier)!
        XCTAssertEqual(SwiftLintFrameworkTests.violations(longerFunctionBody, config: config2), [StyleViolation(
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
    static var allTests: [(String, (FunctionBodyLengthRuleTests) -> () throws -> Void)] {
        return [
            ("testFunctionBodyLengths",
                testFunctionBodyLengths),
            ("testFunctionBodyLengthsWithComments",
                testFunctionBodyLengthsWithComments),
            ("testFunctionBodyLengthsWithMultilineComments",
                testFunctionBodyLengthsWithMultilineComments),
            ("testFunctionBodyLengthsWithExcludedPatterns",
                testFunctionBodyLengthsWithExcludedPatterns)
        ]
    }
}
