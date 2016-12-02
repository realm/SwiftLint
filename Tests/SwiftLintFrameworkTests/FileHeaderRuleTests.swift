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
        verifyRule(FileHeaderRule.description, commentDoesntViolate: false)
    }

    func testFileHeaderWithRequiredString() {
        let description = RuleDescription(
            identifier: "file_header",
            name: "File Header",
            description: "Files should not have header comments.",
            nonTriggeringExamples: [
                "// **Header",
                "//\n // **Header"
            ],
            triggeringExamples: [
                "// Copyright\n",
                "let foo = \"**Header\"",
                "let foo = 2 // **Header",
                "let foo = 2\n // **Header",
                "let foo = 2 // **Header"
            ]
        )

        verifyRule(description, ruleConfiguration: ["required_string": "**Header"],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }

    func testFileHeaderWithRequiredPattern() {
        let description = RuleDescription(
            identifier: "file_header",
            name: "File Header",
            description: "Files should not have header comments.",
            nonTriggeringExamples: [
                "// Copyright © 2016 Realm",
                "//\n // Copyright © 2016 Realm"
            ],
            triggeringExamples: [
                "// Copyright\n",
                "// Copyright © foo Realm",
                "// Copyright © 2016 MyCompany"
            ]
        )

        verifyRule(description, ruleConfiguration: ["required_pattern": "\\d{4} Realm"],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }

    func testFileHeaderWithForbiddenString() {
        let description = RuleDescription(
            identifier: "file_header",
            name: "File Header",
            description: "Files should not have header comments.",
            nonTriggeringExamples: [
                "// Copyright\n",
                "let foo = \"**All rights reserved.\"",
                "let foo = 2 // **All rights reserved.",
                "let foo = 2\n // **All rights reserved.",
                "let foo = 2 // **All rights reserved."
            ],
            triggeringExamples: [
                "// **All rights reserved.",
                "//\n // **All rights reserved."
            ]
        )

        verifyRule(description, ruleConfiguration: ["forbidden_string": "**All rights reserved."],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }

    func testFileHeaderWithForbiddenPattern() {
        let description = RuleDescription(
            identifier: "file_header",
            name: "File Header",
            description: "Files should not have header comments.",
            nonTriggeringExamples: [
                "// Copyright\n",
                "// FileHeaderRuleTests.m\n",
                "let foo = \"FileHeaderRuleTests.swift\"",
                "let foo = 2 // FileHeaderRuleTests.swift.",
                "let foo = 2\n // FileHeaderRuleTests.swift."
            ],
            triggeringExamples: [
                "// FileHeaderRuleTests.swift",
                "//\n // FileHeaderRuleTests.swift"
            ]
        )

        verifyRule(description, ruleConfiguration: ["forbidden_pattern": ".*\\.swift"],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }
}
