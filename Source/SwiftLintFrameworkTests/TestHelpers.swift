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

private func violations(string: String, _ type: StyleViolationType) -> [StyleViolation] {
    return violations(string).filter { $0.type == type }
}

extension XCTestCase {
    func verifyRule(rule: RuleExample,
        type: StyleViolationType,
        commentDoesntViolate: Bool = true) {
        XCTAssertEqual(rule.nonTriggeringExamples.flatMap({violations($0, type)}), [])
        XCTAssertEqual(rule.triggeringExamples.flatMap({violations($0, type).map({$0.type})}),
            Array(count: rule.triggeringExamples.count, repeatedValue: type))

        if commentDoesntViolate {
            XCTAssertEqual(rule.triggeringExamples.flatMap({violations("// " + $0, type)}), [])
        }
    }
}
