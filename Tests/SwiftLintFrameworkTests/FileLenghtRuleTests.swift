//
//  FileLengthRuleTests.swift
//  SwiftLint
//
//  Created by Samuel Susla on 11/07/17.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class FileLenghtRuleTests: XCTestCase {
    private static let triggeringExamples = [
        repeatElement("print(\"swiftlint\")\n", count: 401).joined()
    ]

    private static let nonTriggeringExamples = [
        (repeatElement("print(\"swiftlint\")\n", count: 400) + ["//\n"]).joined(),
        repeatElement("print(\"swiftlint\")\n", count: 400).joined()
    ]

    private let fileLenghRuleDescription = FileLengthRule.description
        .with(nonTriggeringExamples: FileLenghtRuleTests.nonTriggeringExamples)
        .with(triggeringExamples: FileLenghtRuleTests.triggeringExamples)

    func testFileLengthRuleIgnoringLinesWithOnlyComments() {
        // Verify TrailingCommaRule with test values for when mandatory_comma is true.
        let ruleDescription = fileLenghRuleDescription
        let ruleConfiguration = ["ignore_comment_only_lines": true]

        verifyRule(ruleDescription, ruleConfiguration: ruleConfiguration)
    }
}
