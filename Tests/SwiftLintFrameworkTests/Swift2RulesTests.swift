//
//  Swift2RulesTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/30/16.
//  Copyright © 2016 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

#if !SWIFT_PACKAGE
class Swift2RulesTests: XCTestCase {

    func testAttributes() {
        let description = RuleDescription(
            identifier: AttributesRule.description.identifier,
            name: AttributesRule.description.name,
            description: AttributesRule.description.description,
            nonTriggeringExamples: AttributesRuleExamples.swift2NonTriggeringExamples,
            triggeringExamples: AttributesRuleExamples.swift2TriggeringExamples
        )

        verifyRule(description)
    }

    func testNumberSeparator() {
        let description = RuleDescription(
            identifier: NumberSeparatorRule.description.identifier,
            name: NumberSeparatorRule.description.name,
            description: NumberSeparatorRule.description.description,
            nonTriggeringExamples: NumberSeparatorRuleExamples.nonTriggeringExamples,
            triggeringExamples: NumberSeparatorRuleExamples.swift2TriggeringExamples,
            corrections: NumberSeparatorRuleExamples.swift2Corrections
        )

        verifyRule(description)
    }

    func testTypeName() {
        let description = RuleDescription(
            identifier: TypeNameRule.description.identifier,
            name: TypeNameRule.description.name,
            description: TypeNameRule.description.description,
            nonTriggeringExamples: TypeNameRuleExamples.swift2NonTriggeringExamples,
            triggeringExamples: TypeNameRuleExamples.swift2TriggeringExamples
        )

        verifyRule(description)
    }
}
#endif
