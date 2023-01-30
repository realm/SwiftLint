@testable import SwiftLintFramework
import XCTest

class DiscouragedDirectInitRuleTests: XCTestCase {
    private let baseDescription = DiscouragedDirectInitRule.description

    func testDiscouragedDirectInitWithConfiguredSeverity() async throws {
        try await verifyRule(baseDescription, ruleConfiguration: ["severity": "error"])
    }

    func testDiscouragedDirectInitWithNewIncludedTypes() async throws {
        let triggeringExamples = [
            Example("let foo = ↓Foo()"),
            Example("let bar = ↓Bar()")
        ]

        let nonTriggeringExamples = [
            Example("let foo = Foo(arg: toto)"),
            Example("let bar = Bar(arg: \"toto\")")
        ]

        let description = baseDescription
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["types": ["Foo", "Bar"]])
    }

    func testDiscouragedDirectInitWithReplacedTypes() async throws {
        let triggeringExamples = [
            Example("let bundle = ↓Bundle()")
        ]

        let nonTriggeringExamples = [
            Example("let device = UIDevice()")
        ]

        let description = baseDescription
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["types": ["Bundle"]])
    }
}
