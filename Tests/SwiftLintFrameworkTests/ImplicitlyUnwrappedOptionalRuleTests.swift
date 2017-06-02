//
//  ImplicitlyUnwrappedOptionalRuleTests.swift
//  SwiftLint
//
//  Created by Siarhei Fedartsou on 18/03/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
@testable import SwiftLintFramework
import XCTest

class ImplicitlyUnwrappedOptionalRuleTests: XCTestCase {

    func testImplicitlyUnwrappedOptionalRuleDefaultConfiguration() {
        let rule = ImplicitlyUnwrappedOptionalRule()
        XCTAssertEqual(rule.configuration.mode, .allExceptIBOutlets)
        XCTAssertEqual(rule.configuration.severity.severity, .warning)
    }

    func testImplicitlyUnwrappedOptionalRuleWarnsOnOutletsInAllMode() {
        let baseDescription = ImplicitlyUnwrappedOptionalRule.description
        let triggeringExamples = [
            "@IBOutlet private var label: UILabel!",
            "@IBOutlet var label: UILabel!",
            "let int: Int!"
        ]

        let nonTriggeringExamples = ["if !boolean {}"]
        let description = RuleDescription(identifier: baseDescription.identifier,
                                          name: baseDescription.name,
                                          description: baseDescription.description,
                                          nonTriggeringExamples: nonTriggeringExamples,
                                          triggeringExamples: triggeringExamples,
                                          corrections: baseDescription.corrections)
        verifyRule(description, ruleConfiguration: ["mode": "all"],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }
}
