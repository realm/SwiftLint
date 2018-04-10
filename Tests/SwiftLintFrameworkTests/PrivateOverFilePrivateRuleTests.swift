//
//  PrivateOverFilePrivateRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 08/01/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class PrivateOverFilePrivateRuleTests: XCTestCase {

    func testPrivateOverFilePrivateWithDefaultConfiguration() {
        verifyRule(PrivateOverFilePrivateRule.description)
    }

    func testPrivateOverFilePrivateValidatingExtensions() {
        let baseDescription = PrivateOverFilePrivateRule.description
        let triggeringExamples = baseDescription.triggeringExamples + [
            "↓fileprivate extension String {}",
            "↓fileprivate \n extension String {}",
            "↓fileprivate extension \n String {}"
        ]
        let corrections = [
            "↓fileprivate extension String {}": "private extension String {}",
            "↓fileprivate \n extension String {}": "private \n extension String {}",
            "↓fileprivate extension \n String {}": "private extension \n String {}"
        ]

        let description = baseDescription.with(nonTriggeringExamples: [])
            .with(triggeringExamples: triggeringExamples).with(corrections: corrections)
        verifyRule(description, ruleConfiguration: ["validate_extensions": true])
    }

    func testPrivateOverFilePrivateNotValidatingExtensions() {
        let baseDescription = PrivateOverFilePrivateRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            "fileprivate extension String {}"
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["validate_extensions": false])
    }
}
