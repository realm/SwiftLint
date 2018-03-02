//
//  SubClassRuleTests.swift
//  SwiftLint
//
//  Created by Mikhail Yakushin on 03/02/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class SubClassRuleTests: XCTestCase {

    func testSubClassRuleSuperDot() {
        let nonTriggeringExamples =
            "class MyType: SuperType {" +
                "public init() { super.init() }" +
                "}"
        XCTAssertNotEqual(violations(nonTriggeringExamples), [])
    }

    func testSubClassRuleSuper() {
        let nonTriggeringExamples =
            "class MyType: SuperType {" +
                "public init() { super() }" +
            "}"
        XCTAssertNotEqual(violations(nonTriggeringExamples), [])
    }

    func testSubClassRuleTestsValid() {
        let nonTriggeringExamples =
            "class MyType: SuperType {" +
                "public init() { this() }" +
            "}"
        XCTAssertEqual(violations(nonTriggeringExamples), [])
    }

    private func violations(_ string: String) -> [StyleViolation] {
        let config = makeConfig(nil, SubClassRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(string, config: config)
    }

}
