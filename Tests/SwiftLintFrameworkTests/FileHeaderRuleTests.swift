//
//  FileHeaderRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class FileHeaderRuleTests: XCTestCase {

    func testFileHeaderWithDefaultConfiguration() {
        verifyRule(FileHeaderRule.description, skipCommentTests: true)
    }

    func testFileHeaderWithRequiredString() {
        let description = RuleDescription(
            identifier: FileHeaderRule.description.identifier,
            name: FileHeaderRule.description.name,
            description: FileHeaderRule.description.description,
            nonTriggeringExamples: [
                "// **Header",
                "//\n // **Header"
            ],
            triggeringExamples: [
                "↓// Copyright\n",
                "let foo = \"**Header\"",
                "let foo = 2 // **Header",
                "let foo = 2\n // **Header",
                "let foo = 2 // **Header"
            ]
        )

        verifyRule(description, ruleConfiguration: ["required_string": "**Header"],
                   stringDoesntViolate: false, skipCommentTests: true, testMultiByteOffsets: false)
    }

    func testFileHeaderWithRequiredPattern() {
        let description = RuleDescription(
            identifier: FileHeaderRule.description.identifier,
            name: FileHeaderRule.description.name,
            description: FileHeaderRule.description.description,
            nonTriggeringExamples: [
                "// Copyright © 2016 Realm",
                "//\n // Copyright © 2016 Realm"
            ],
            triggeringExamples: [
                "↓// Copyright\n",
                "↓// Copyright © foo Realm",
                "↓// Copyright © 2016 MyCompany"
            ]
        )

        verifyRule(description, ruleConfiguration: ["required_pattern": "\\d{4} Realm"],
                   stringDoesntViolate: false, skipCommentTests: true, testMultiByteOffsets: false)
    }

    func testFileHeaderWithForbiddenString() {
        let description = RuleDescription(
            identifier: FileHeaderRule.description.identifier,
            name: FileHeaderRule.description.name,
            description: FileHeaderRule.description.description,
            nonTriggeringExamples: [
                "// Copyright\n",
                "let foo = \"**All rights reserved.\"",
                "let foo = 2 // **All rights reserved.",
                "let foo = 2\n // **All rights reserved.",
                "let foo = 2 // **All rights reserved."
            ],
            triggeringExamples: [
                "// ↓**All rights reserved.",
                "//\n // ↓**All rights reserved."
            ]
        )

        verifyRule(description, ruleConfiguration: ["forbidden_string": "**All rights reserved."],
                   skipCommentTests: true)
    }

    func testFileHeaderWithForbiddenPattern() {
        let description = RuleDescription(
            identifier: FileHeaderRule.description.identifier,
            name: FileHeaderRule.description.name,
            description: FileHeaderRule.description.description,
            nonTriggeringExamples: [
                "// Copyright\n",
                "// FileHeaderRuleTests.m\n",
                "let foo = \"FileHeaderRuleTests.swift\"",
                "let foo = 2 // FileHeaderRuleTests.swift.",
                "let foo = 2\n // FileHeaderRuleTests.swift."
            ],
            triggeringExamples: [
                "//↓ FileHeaderRuleTests.swift",
                "//\n //↓ FileHeaderRuleTests.swift"
            ]
        )

        verifyRule(description, ruleConfiguration: ["forbidden_pattern": "\\s\\w+\\.swift"],
                   skipCommentTests: true)
    }
}
