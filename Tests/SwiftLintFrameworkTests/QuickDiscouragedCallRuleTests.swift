//
//  QuickDiscouragedCallRuleTests.swift
//  SwiftLint
//
//  Created by Omer Murat Aydin on 28.12.2024.
//

@testable import SwiftLintBuiltInRules
import XCTest
@testable import SwiftLintFramework

class QuickDiscouragedCallRuleTests: XCTestCase {
    
    func lint(_ content: String) -> [StyleViolation] {
        let file = SwiftLintFile(contents: content)
        return QuickDiscouragedCallRule().validate(file: file)
    }

    func testQuickDiscouragedCallRule() {
        // Example of correct usage (should not trigger a warning)
        let nonTriggeringExamples = [
            "@TestState var foo = Foo()" // This should not trigger a warning
        ]

        // Example of incorrect usage (should trigger a warning)
        let triggeringExamples = [
            "describe(\"foo\") { @TestState var foo = Foo() }" // This should trigger a warning
        ]

        // Test for correct usage
        nonTriggeringExamples.forEach { example in
            XCTAssertEqual(lint(example), [])
        }

        // Test for incorrect usage
        triggeringExamples.forEach { example in
            XCTAssertFalse(lint(example).isEmpty)
        }
    }
}
