@testable import SwiftLintFramework
import XCTest

final class PrefixedTopLevelConstantRuleTests: XCTestCase {
    func testDefaultConfiguration() {
        verifyRule(PrefixedTopLevelConstantRule.description)
    }

    func testPrivateOnly() {
        let triggeringExamples = [
            Example("private let ↓Foo = 20.0"),
            Example("fileprivate let ↓foo = 20.0")
        ]
        let nonTriggeringExamples = [
            Example("let Foo = 20.0"),
            Example("internal let Foo = \"Foo\""),
            Example("public let Foo = 20.0")
        ]

        let description = PrefixedTopLevelConstantRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["only_private": true])
    }
}
