//
//  UnusedOptionalBindingRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 05/01/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
@testable import SwiftLintFramework
import XCTest

class UnusedOptionalBindingRuleTests: XCTestCase {

    func testDefaultConfiguration() {
        let baseDescription = UnusedOptionalBindingRule.description
        let triggeringExamples = baseDescription.triggeringExamples + [
            "guard let _ = try? alwaysThrows() else { return }"
        ]
        let description = RuleDescription(identifier: baseDescription.identifier,
                                          name: baseDescription.name,
                                          description: baseDescription.description,
                                          nonTriggeringExamples: baseDescription.nonTriggeringExamples,
                                          triggeringExamples: triggeringExamples,
                                          corrections: baseDescription.corrections)

        verifyRule(description)
    }

    func testIgnoreOptionalTryEnabled() {
        // Perform additional tests with the ignore_optional_try settings enabled.
        let baseDescription = UnusedOptionalBindingRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            "guard let _ = try? alwaysThrows() else { return }"
        ]
        let description = RuleDescription(identifier: baseDescription.identifier,
                                          name: baseDescription.name,
                                          description: baseDescription.description,
                                          nonTriggeringExamples: nonTriggeringExamples,
                                          triggeringExamples: baseDescription.triggeringExamples,
                                          corrections: baseDescription.corrections)

        verifyRule(description, ruleConfiguration: ["ignore_optional_try": true])
    }
}
