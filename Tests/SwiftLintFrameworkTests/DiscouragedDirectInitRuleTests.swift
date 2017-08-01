//
//  DiscouragedDirectInitRuleTests.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/1/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SwiftLintFramework
import XCTest

class DiscouragedDirectInitRuleTests: XCTestCase {
    let baseDescription = DiscouragedDirectInitRule.description

    func testDiscouragedDirectInitWithDefaultConfiguration() {
        verifyRule(baseDescription)
    }

    func testDiscouragedDirectInitWithConfiguredSeverity() {
        verifyRule(baseDescription, ruleConfiguration: ["severity": "error"])
    }

    func testDiscouragedDirectInitWithNewIncludedTypes() {
        let triggeringExamples = [
            "let foo = ↓Foo()",
            "let bar = ↓Bar()"
        ]

        let nonTriggeringExamples = [
            "let foo = Foo(arg: toto)",
            "let bar = Bar(arg: \"toto\")"
        ]

        let description = baseDescription
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["types": ["Foo", "Bar"]])
    }

    func testDiscouragedDirectInitWithReplacedTypes() {
        let triggeringExamples = [
            "let bundle = ↓Bundle()"
        ]

        let nonTriggeringExamples = [
            "let device = UIDevice()"
        ]

        let description = baseDescription
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["types": ["Bundle"]])
    }
}
