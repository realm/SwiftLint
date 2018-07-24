@testable import SwiftLintFramework
import XCTest

final class PrefixedTopLevelConstantRuleTests: XCTestCase {
    func testDefaultConfiguration() {
        verifyRule(PrefixedTopLevelConstantRule.description)
    }

    func testPrivateOnly() {
        let triggeringExamples = [
            "private let ↓Foo = 20.0",
            "fileprivate let ↓foo = 20.0"
        ]
        let nonTriggeringExamples = [
            "let Foo = 20.0",
            "internal let Foo = \"Foo\"",
            "public let Foo = 20.0"
        ]

        let description = PrefixedTopLevelConstantRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["only_private": true])
    }
}
