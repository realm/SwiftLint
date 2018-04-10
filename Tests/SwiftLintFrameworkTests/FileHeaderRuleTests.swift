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
        let nonTriggeringExamples = [
            "// **Header",
            "//\n// **Header"
        ]
        let triggeringExamples = [
            "↓// Copyright\n",
            "let foo = \"**Header\"",
            "let foo = 2 // **Header",
            "let foo = 2\n// **Header",
            "let foo = 2 // **Header"
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["required_string": "**Header"],
                   stringDoesntViolate: false, skipCommentTests: true,
                   testMultiByteOffsets: false, testShebang: false)
    }

    func testFileHeaderWithRequiredPattern() {
        let nonTriggeringExamples = [
            "// Copyright © 2016 Realm",
            "//\n// Copyright © 2016 Realm"
        ]
        let triggeringExamples = [
            "↓// Copyright\n",
            "↓// Copyright © foo Realm",
            "↓// Copyright © 2016 MyCompany"
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["required_pattern": "\\d{4} Realm"],
                   stringDoesntViolate: false, skipCommentTests: true,
                   testMultiByteOffsets: false)
    }

    func testFileHeaderWithRequiredStringAndURLComment() {
        let nonTriggeringExamples = [
            "/* Check this url: https://github.com/realm/SwiftLint */"
        ]
        let triggeringExamples = [
            "/* Check this url: https://github.com/apple/swift */"
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        let config = ["required_string": "/* Check this url: https://github.com/realm/SwiftLint */"]
        verifyRule(description, ruleConfiguration: config,
                   stringDoesntViolate: false, skipCommentTests: true,
                   testMultiByteOffsets: false)
    }

    func testFileHeaderWithForbiddenString() {
        let nonTriggeringExamples = [
            "// Copyright\n",
            "let foo = \"**All rights reserved.\"",
            "let foo = 2 // **All rights reserved.",
            "let foo = 2\n// **All rights reserved.",
            "let foo = 2 // **All rights reserved."
        ]
        let triggeringExamples = [
            "// ↓**All rights reserved.",
            "//\n// ↓**All rights reserved."
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["forbidden_string": "**All rights reserved."],
                   skipCommentTests: true)
    }

    func testFileHeaderWithForbiddenPattern() {
        let nonTriggeringExamples = [
            "// Copyright\n",
            "// FileHeaderRuleTests.m\n",
            "let foo = \"FileHeaderRuleTests.swift\"",
            "let foo = 2 // FileHeaderRuleTests.swift.",
            "let foo = 2\n // FileHeaderRuleTests.swift."
        ]
        let triggeringExamples = [
            "//↓ FileHeaderRuleTests.swift",
            "//\n//↓ FileHeaderRuleTests.swift"
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["forbidden_pattern": "\\s\\w+\\.swift"],
                   skipCommentTests: true)
    }

    func testFileHeaderWithForbiddenPatternAndDocComment() {
        let nonTriggeringExamples = [
            "/// This is great tool with tests.\nclass GreatTool {}",
            "class GreatTool {}"
        ]
        let triggeringExamples = [
            "// FileHeaderRule↓Tests.swift",
            "//\n// FileHeaderRule↓Tests.swift"
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["forbidden_pattern": "[tT]ests"],
                   skipCommentTests: true, testMultiByteOffsets: false)
    }
}
