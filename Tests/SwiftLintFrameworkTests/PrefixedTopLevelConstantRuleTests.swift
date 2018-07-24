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

        let alwaysOnSameLineDescription = PrefixedTopLevelConstantRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(alwaysOnSameLineDescription,
                   ruleConfiguration: ["only_private": true])
    }
}
