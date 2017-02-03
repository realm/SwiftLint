//
//  TypeNameRuleTests.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 01/18/17.
//  Copyright © 2017 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

class TypeNameRuleTests: XCTestCase {

    func testTypeNameWithDefaultConfiguration() {
        // Test with default parameters
        verifyRule(VariableNameRule.description)
    }

    func testTypeNameWithAdditionalAllowedCharacters() {
        // Test with custom `additional_allowed_characters`
        let typeNameDescription = RuleDescription(
            identifier: TypeNameRule.description.identifier,
            name: TypeNameRule.description.name,
            description: TypeNameRule.description.description,
            nonTriggeringExamples: [
                "protocol m_Foo {\n associatedtype Bar\n }"
            ],
            triggeringExamples: [
                "private typealias ↓Foo😎Bar = Void"
            ]
        )

        verifyRule(typeNameDescription,
                   ruleConfiguration: ["min_length": ["warning": 3, "error": 0],
                                       "max_length": ["warning": 40, "error": 1000],
                                       "additional_allowed_characters": "_"])
    }
}

extension TypeNameRuleTests {
    static var allTests: [(String, (TypeNameRuleTests) -> () throws -> Void)] {
        return [
            ("testTypeNameWithDefaultConfiguration", testTypeNameWithDefaultConfiguration),
            ("testTypeNameWithAdditionalAllowedCharacters", testTypeNameWithAdditionalAllowedCharacters)
        ]
    }
}
