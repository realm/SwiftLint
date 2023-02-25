@testable import SwiftLintFramework
import XCTest

class IdentifierNameRuleTests: XCTestCase {
    func testIdentifierNameWithExcluded() async throws {
        let baseDescription = IdentifierNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("let Apple = 0"),
            Example("let some_apple = 0"),
            Example("let Test123 = 0")
        ]
        let triggeringExamples = baseDescription.triggeringExamples + [
            Example("let ap_ple = 0"),
            Example("let AppleJuice = 0")
        ]
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        try await verifyRule(description, ruleConfiguration: ["excluded": ["Apple", "some.*", ".*\\d+.*"]])
    }

    func testIdentifierNameWithAllowedSymbols() async throws {
        let baseDescription = IdentifierNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("let myLet$ = 0"),
            Example("let myLet% = 0"),
            Example("let myLet$% = 0"),
            Example("let _myLet = 0")
        ]
        let triggeringExamples = baseDescription.triggeringExamples.filter { !$0.code.contains("_") }
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        try await verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%", "_"]])
    }

    func testIdentifierNameWithAllowedSymbolsAndViolation() async throws {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamples = [
            Example("↓let my_Let$ = 0")
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        try await verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testIdentifierNameWithIgnoreStartWithLowercase() async throws {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamplesToRemove = [
            Example("↓let MyLet = 0"),
            Example("enum Foo { case ↓MyEnum }"),
            Example("↓func IsOperator(name: String) -> Bool")
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples +
            triggeringExamplesToRemove.removingViolationMarkers()
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": false])
    }

    func testLinuxCrashOnEmojiNames() async throws {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamples = [
            Example("let 👦🏼 = \"👦🏼\"")
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        try await verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }
}
