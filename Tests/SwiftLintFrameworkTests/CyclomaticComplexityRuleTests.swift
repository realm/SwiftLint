//
//  CyclomaticComplexityRuleTests.swift
//  SwiftLint
//
//  Created by Mike Welles on 2/9/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SwiftLintFramework
import XCTest

class CyclomaticComplexityRuleTests: XCTestCase {
    lazy var complexSwitchExample: String = {
        var example = "func switcheroo() {\n"
        example += "    switch foo {\n"
        for i in (0...30) {
            example += "  case \(i):   print(\"\(i)\")\n"
        }
        example += "    }\n"
        example += "}\n"
        return example
    }()

    lazy var complexIfExample: String = {
        let nest = 22
        var example = "func nestThoseIfs() {\n"
        for i in (0...nest) {
            let indent = String(repeating: "    ", count: i + 1)
            example += indent + "if false != true {\n"
            example += indent + "   print \"\\(i)\"\n"
        }

        for i in (0...nest).reversed() {
            let indent = String(repeating: "    ", count: i + 1)
            example += indent + "}\n"
        }
        example += "}\n"
        return example
    }()

    func testCyclomaticComplexity() {
        verifyRule(CyclomaticComplexityRule.description, commentDoesntViolate: true, stringDoesntViolate: true)
    }

    func testIgnoresCaseStatementsConfigurationEnabled() {
        let baseDescription = CyclomaticComplexityRule.description
        let triggeringExamples = [complexIfExample]
        var nonTriggeringExamples = baseDescription.nonTriggeringExamples
        nonTriggeringExamples.append(complexSwitchExample)
        let description = RuleDescription(identifier: baseDescription.identifier,
                                          name: baseDescription.name,
                                          description: baseDescription.description,
                                          nonTriggeringExamples: nonTriggeringExamples,
                                          triggeringExamples: triggeringExamples,
                                          corrections: baseDescription.corrections)
        verifyRule(description, ruleConfiguration: ["ignores_case_statements": true],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }

    func testIgnoresCaseStatementsConfigurationDisabled() {
        let baseDescription = CyclomaticComplexityRule.description
        var triggeringExamples = baseDescription.triggeringExamples
        triggeringExamples.append(complexSwitchExample)
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples
        let description = RuleDescription(identifier: baseDescription.identifier,
                                          name: baseDescription.name,
                                          description: baseDescription.description,
                                          nonTriggeringExamples: nonTriggeringExamples,
                                          triggeringExamples: triggeringExamples,
                                          corrections: baseDescription.corrections)
        verifyRule(description, ruleConfiguration: ["ignores_case_statements": false],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }

}
