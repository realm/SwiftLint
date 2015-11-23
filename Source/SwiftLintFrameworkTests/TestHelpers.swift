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

extension String {
    private func toStringLiteral() -> String {
        return "\"" + stringByReplacingOccurrencesOfString("\n", withString: "\\n") + "\""
    }
}

extension XCTestCase {
    func verifyRule(ruleDescription: RuleDescription, commentDoesntViolate: Bool = true,
                    stringDoesntViolate: Bool = true) {

        // Non-triggering examples don't violate
        XCTAssert(
            ruleDescription.nonTriggeringExamples.flatMap({
                violations($0, ruleDescription)
            }).isEmpty
        )

        // Triggering examples violate
        XCTAssertEqual(
            ruleDescription.triggeringExamples.flatMap({ violations($0, ruleDescription) }).count,
            ruleDescription.triggeringExamples.count
        )

        // Comment doesn't violate
        XCTAssertEqual(
            ruleDescription.triggeringExamples.flatMap({
                violations("/*\n  " + $0 + "\n */", ruleDescription)
            }).count,
            commentDoesntViolate ? 0 : ruleDescription.triggeringExamples.count
        )

        // String doesn't violate
        XCTAssertEqual(
            ruleDescription.triggeringExamples.flatMap({
                violations($0.toStringLiteral(), ruleDescription)
            }).count,
            stringDoesntViolate ? 0 : ruleDescription.triggeringExamples.count
        )

        // "disable" command doesn't violate
        let command = "// swiftlint:disable \(ruleDescription.identifier)\n"
        XCTAssert(
            ruleDescription.triggeringExamples.flatMap({
                violations(command + $0, ruleDescription)
            }).isEmpty
        )
    }
}
