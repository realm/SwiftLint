//
//  DisableAllTests.swift
//  SwiftLint
//
//  Created by Frederick Pietschmann on 3/11/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
@testable import SwiftLintFramework
import XCTest

class DisableAllTests: XCTestCase {
     /// Example violation (identifer_name). Could be replaced with any other single violation.
    private let violatingPhrase = "let r = 0\n"

    /// Tests whether example violating phrase triggers when not applying disable rule
    func testViolatingPhrase() {
        print(violations(violatingPhrase))
        XCTAssertEqual(violations(violatingPhrase).count, 1)
    }

    /// Tests swiftlint:disable:all protects properly
    func testDisableAll() {
        let protectedPhrase = "// swiftlint:disable all\n" + violatingPhrase
        XCTAssertEqual(violations(protectedPhrase).count, 0)
    }

    /// Tests swiftlint:enable all unprotects properly
    func testEnableAll() {
        let unprotectedPhrase =
            "// swiftlint:disable all\n" +
            violatingPhrase +
            "// swiftlint:enable all\n" +
            violatingPhrase
        XCTAssertEqual(violations(unprotectedPhrase).count, 1)
    }
}
