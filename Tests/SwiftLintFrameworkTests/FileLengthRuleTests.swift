//
//  FileLengthRuleTests.swift
//  SwiftLint
//
//  Created by Samuel Susla on 11/07/17.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class FileLengthRuleTests: XCTestCase {

    func testFileLengthWithDefaultConfiguration() {
        verifyRule(FileLengthRule.description, commentDoesntViolate: false,
                   testMultiByteOffsets: false, testShebang: false)
    }

    func testFileLengthIgnoringLinesWithOnlyComments() {
        let triggeringExamples = [
            repeatElement("print(\"swiftlint\")\n", count: 401).joined()
        ]
        let nonTriggeringExamples = [
            (repeatElement("print(\"swiftlint\")\n", count: 400) + ["//\n"]).joined(),
            repeatElement("print(\"swiftlint\")\n", count: 400).joined()
        ]

        let description = FileLengthRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignore_comment_only_lines": true],
                   testMultiByteOffsets: false, testShebang: false)
    }
}
