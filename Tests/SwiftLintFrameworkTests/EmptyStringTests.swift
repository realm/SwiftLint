//
//  EmptyStringsTests.swift
//  SwiftLint
//
//  Created by Davide Sibilio on 02/22/18.
//  Copyright © 2017 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class EmptyStringTests: XCTestCase {

    func testEqualToEmptyString() {
        let string = "if myString == \"\" {"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
    }

    func testDisequalToEmptyString() {
        let string = "if myString != \"\" {"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
    }

    private func violations(_ string: String) -> [StyleViolation] {
        let config = makeConfig(nil, EmptyStringRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(string, config: config)
    }
}
