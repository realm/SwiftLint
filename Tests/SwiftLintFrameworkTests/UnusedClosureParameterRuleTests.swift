//
//  UnusedClosureParameterRuleTests.swift
//  SwiftLint
//
//  Created by Woosik Byun on 07/06/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
@testable import SwiftLintFramework
import XCTest

class UnusedClosureParameterRuleTests: XCTestCase {

    func testDefaultConfiguration() {
        let baseDescription = UnusedClosureParameterRule.description
        let description = RuleDescription(identifier: baseDescription.identifier,
                                          name: baseDescription.name,
                                          description: baseDescription.description,
                                          nonTriggeringExamples: baseDescription.nonTriggeringExamples,
                                          triggeringExamples: baseDescription.triggeringExamples,
                                          corrections: baseDescription.corrections)

        verifyRule(description)
    }
}
