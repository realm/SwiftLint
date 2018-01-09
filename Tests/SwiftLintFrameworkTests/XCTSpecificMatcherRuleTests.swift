//
//  XCTSpecificMatcherRuleTests.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 1/9/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class XCTSpecificMatcherRuleTests: XCTestCase {

    func testRule() {
        verifyRule(XCTSpecificMatcherRule.description)
    }

    // MARK: - Additional Tests

    func testEqualNilNil() {
        let string = "XCTAssertEqual(nil, nil)"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "Prefer the specific matcher 'XCTAssertNil' instead.")
    }

    func testEqualTrueTrue() {
        let string = "XCTAssertEqual(true, true)"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "Prefer the specific matcher 'XCTAssertTrue' instead.")
    }

    func testEqualFalseFalse() {
        let string = "XCTAssertEqual(false, false)"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "Prefer the specific matcher 'XCTAssertFalse' instead.")
    }

    private func violations(_ string: String) -> [StyleViolation] {
        let config = makeConfig(nil, XCTSpecificMatcherRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(string, config: config)
    }
}
