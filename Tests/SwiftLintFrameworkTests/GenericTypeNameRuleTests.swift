//
//  GenericTypeNameRuleTests.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 01/20/17.
//  Copyright © 2017 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

class GenericTypeNameRuleTests: XCTestCase {

    func testGenericTypeNameWithDefaultConfiguration() {
        // Test with default parameters
        verifyRule(GenericTypeNameRule.description)
    }

    func testGenericTypeNameWithAdditionalAllowedCharacters() {
        // Test with custom `additional_allowed_characters`
        let genericTypeNameDescription = RuleDescription(
            identifier: GenericTypeNameRule.description.identifier,
            name: GenericTypeNameRule.description.name,
            description: GenericTypeNameRule.description.description,
            nonTriggeringExamples: [
                "func foo<T_Foo>() {}\n"
            ],
            triggeringExamples: [
                "func foo<↓T🤣Foo>() {}\n"
            ]
        )

        verifyRule(genericTypeNameDescription,
                   ruleConfiguration: ["min_length": ["warning": 3, "error": 2],
                                       "max_length": ["warning": 40, "error": 60],
                                       "additional_allowed_characters": "_"])
    }
}

extension GenericTypeNameRuleTests {
    static var allTests: [(String, (GenericTypeNameRuleTests) -> () throws -> Void)] {
        return [
            ("testGenericTypeNameWithDefaultConfiguration", testGenericTypeNameWithDefaultConfiguration),
            ("testGenericTypeNameWithAdditionalAllowedCharacters", testGenericTypeNameWithAdditionalAllowedCharacters)
        ]
    }
}
