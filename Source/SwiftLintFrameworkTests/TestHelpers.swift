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

func violations(string: String) -> [StyleViolation] {
    return Linter(file: File(contents: string)).styleViolations
}

private func violations(string: String, _ description: RuleDescription) -> [StyleViolation] {
    return violations(string).filter { $0.ruleDescription == description }
}

extension XCTestCase {
    func verifyRule(ruleDescription: RuleDescription, commentDoesntViolate: Bool = true) {
        XCTAssertEqual(
            ruleDescription.nonTriggeringExamples.flatMap({violations($0, ruleDescription)}),
            []
        )
        XCTAssertEqual(
            ruleDescription.triggeringExamples.flatMap({ example in
                violations(example, ruleDescription).map({$0.ruleDescription})
            }),
            Array(count: ruleDescription.triggeringExamples.count, repeatedValue: ruleDescription)
        )

        let commentedViolations = ruleDescription.triggeringExamples.flatMap { example in
            violations("/**\n  " + example + "\n */", ruleDescription)
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
