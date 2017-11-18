//
//  TypeNameRuleTests.swift
//  SwiftLint
//
//  Created by Javier Hernandez on 30/04/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class TypeNameRuleTests: XCTestCase {

    func testTypeName() {
        verifyRule(TypeNameRule.description)
    }

    func testTypeNameWithAllowedSymbols() {
        let baseDescription = TypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            "class MyType$ {}",
            "struct MyType$ {}",
            "enum MyType$ {}",
            "typealias Foo$ = Void",
            "protocol Foo {\n associatedtype Bar$\n }"
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$"]])
    }

    func testTypeNameWithAllowedSymbolsAndViolation() {
        let baseDescription = TypeNameRule.description
        let triggeringExamples = [
            "class My_Type$ {}"
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testTypeNameWithIgnoreStartWithLowercase() {
        let baseDescription = TypeNameRule.description
        let triggeringExamplesToRemove = [
            "private typealias ↓foo = Void",
            "↓class myType {}",
            "↓struct myType {}",
            "↓enum myType {}"
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples +
            triggeringExamplesToRemove.map { $0.replacingOccurrences(of: "↓", with: "") }
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": false])
    }
}
