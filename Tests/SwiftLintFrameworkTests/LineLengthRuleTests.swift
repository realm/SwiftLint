//
//  LineLengthRuleTests.swift
//  SwiftLint
//
//  Created by Javier Hernández on 06/01/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

class LineLengthRuleTests: XCTestCase {

    func testLineLength() {
        verifyRule(LineLengthRule.description, commentDoesntViolate: false, stringDoesntViolate: false)
    }

    func testLineLengthWithIgnoreURLsEnabled() {
        let url = "https://github.com/realm/SwiftLint"
        let triggeringLines = [String(repeating: "/", count: 121) + "\(url)\n"]
        let nonTriggeringLines = ["\(url) " + String(repeating: "/", count: 118) + " \(url)\n",
            "\(url)/" + String(repeating: "a", count: 120)]

        let baseDescription = LineLengthRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + nonTriggeringLines
        let triggeringExamples = baseDescription.triggeringExamples + triggeringLines
        let description = RuleDescription(identifier: baseDescription.identifier,
                                          name: baseDescription.name,
                                          description: baseDescription.description,
                                          nonTriggeringExamples: nonTriggeringExamples,
                                          triggeringExamples: triggeringExamples,
                                          corrections: baseDescription.corrections)

        verifyRule(description, ruleConfiguration: ["ignores_urls": true],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }
}

extension LineLengthRuleTests {
    static var allTests: [(String, (LineLengthRuleTests) -> () throws -> Void)] {
        return [
            ("testLineLength", testLineLength),
            ("testLineLengthWithIgnoreURLsEnabled", testLineLengthWithIgnoreURLsEnabled)
        ]
    }
}
