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

extension XCTestCase {
    func verifyRule(rule: RuleExample,
        type: StyleViolationType,
        commentDoesntViolate: Bool = true) {
        XCTAssertEqual(rule.nonTriggeringExamples.flatMap({violations($0)}), [])
        XCTAssertEqual(rule.triggeringExamples.flatMap({violations($0).map({$0.type})}),
            Array(count: rule.triggeringExamples.count, repeatedValue: type))

        if commentDoesntViolate {
            XCTAssertEqual(rule.triggeringExamples.flatMap({violations("// " + $0)}), [])
        }
    }
}
