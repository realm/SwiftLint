//
//  TypeBodyLengthRuleTests.swift
//  SwiftLint
//
//  Created by Daniel Rodriguez Troitino on 3/17/17.
//  Copyright © 2017 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

class TypeBodyLengthRuleTests: XCTestCase {
    func testTypeBodyLength() {
        verifyRule(TypeBodyLengthRule.description)
    }

    func testTypeBodyLengthWithExcluded() {
        guard let config = makeConfig(["warning": 200, "error": 400, "excluded": ["Abc"]],
                                      TypeBodyLengthRule.description.identifier) else {
            XCTFail()
            return
        }

        for example in TypeBodyLengthRule.description.triggeringExamples {
            XCTAssertEqual(violations(example, config: config), [])
        }
    }
}

extension TypeBodyLengthRuleTests {
    static var allTests: [(String, (TypeBodyLengthRuleTests) -> () throws -> Void)] {
        return [
            ("testTypeBodyLength", testTypeBodyLength),
            ("testTypeBodyLengthWithExcluded", testTypeBodyLengthWithExcluded)
        ]
    }
}
