//
//  ExplicitTypeInterfaceTests.swift
//  SwiftLint
//
//  Created by Rounak Jain on 2/24/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class ExplicitTypeInterfaceTests: XCTestCase {

    func testExplicitTypeInterface() {
        verifyRule(ExplicitTypeInterfaceRule.description)
    }

    func testExcludeLocalVars() {
        let nonTriggeringExamples = ExplicitTypeInterfaceRule.description.nonTriggeringExamples + [
            "func foo() {\nlet intVal = 1\n}",
        ]
        let description = ExplicitTypeInterfaceRule.description.with(triggeringExamples: ExplicitTypeInterfaceRule.description.triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["excluded": ["local"]])
    }

}
