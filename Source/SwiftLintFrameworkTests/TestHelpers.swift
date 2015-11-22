//
//  TestHelpers.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SwiftLintFramework
import SourceKittenFramework
import XCTest

let allRuleIdentifiers = Configuration.rulesFromYAML().map {
    $0.dynamicType.description.identifier
}

func violations(string: String, config: Configuration = Configuration()) -> [StyleViolation] {
    return Linter(file: File(contents: string), configuration: config).styleViolations
}

private func violations(string: String, _ description: RuleDescription) -> [StyleViolation] {
    let disabledRules = allRuleIdentifiers.filter { $0 != description.identifier }
    return violations(string, config: Configuration(disabledRules: disabledRules)!)
}

extension XCTestCase {
    func verifyRule(ruleDescription: RuleDescription, commentDoesntViolate: Bool = true) {
        XCTAssertEqual(
            ruleDescription.nonTriggeringExamples.flatMap({violations($0, ruleDescription)}),
            []
        )
        XCTAssertEqual(
            ruleDescription.triggeringExamples.flatMap({
                violations($0, ruleDescription).map({$0.ruleDescription})
            }),
            Array(count: ruleDescription.triggeringExamples.count, repeatedValue: ruleDescription)
        )

        let commentedViolations = ruleDescription.triggeringExamples.flatMap {
            violations("/*\n  " + $0 + "\n */", ruleDescription)
        }.map({$0.ruleDescription})
        XCTAssertEqual(
            commentedViolations,
            Array(count: commentDoesntViolate ? 0 : ruleDescription.triggeringExamples.count,
                  repeatedValue: ruleDescription)
        )

        let command = "// swiftlint:disable \(ruleDescription.identifier)\n"
        XCTAssertEqual(
            ruleDescription.triggeringExamples.flatMap({violations(command + $0, ruleDescription)}),
            []
        )
    }
}
