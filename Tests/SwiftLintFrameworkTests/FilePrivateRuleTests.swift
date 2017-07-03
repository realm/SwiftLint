//
//  FilePrivateRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 03/07/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class FilePrivateRuleTests: XCTestCase {

    func testFilePrivateWithDefaultConfiguration() {
        verifyRule(FilePrivateRule.description)
    }

    func testFilePrivateWithStrictConfiguration() {
        let nonTriggeringExamples = [
            "extension String {}",
            "private extension String {}",
            "public \n extension String {}",
            "open extension \n String {}",
            "internal extension String {}"
        ]
        let triggeringExamples = [
            "↓fileprivate extension String {}",
            "↓fileprivate extension String {}",
            "↓fileprivate \n extension String {}",
            "↓fileprivate extension \n String {}",
            "↓fileprivate extension String {}",
            "extension String {\n↓fileprivate func Something(){}\n}",
            "class MyClass {\n↓fileprivate let myInt = 4\n}",
            "class MyClass {\n↓fileprivate(set) var myInt = 4\n}",
            "struct Outter {\nstruct Inter {\n↓fileprivate struct Inner {}\n}\n}"
        ]
        let description = FilePrivateRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["strict": true])
    }
}
