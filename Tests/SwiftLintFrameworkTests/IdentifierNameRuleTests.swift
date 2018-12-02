import SwiftLintFramework
import XCTest

class IdentifierNameRuleTests: XCTestCase {
    func testIdentifierName() {
        verifyRule(IdentifierNameRule.description)
    }

    func testIdentifierNameWithAllowedSymbols() {
        let baseDescription = IdentifierNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            "let myLet$ = 0",
            "let myLet% = 0",
            "let myLet$% = 0"
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testIdentifierNameWithAllowedSymbolsAndViolation() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamples = [
            "↓let my_Let$ = 0"
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testIdentifierNameWithIgnoreStartWithLowercase() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamplesToRemove = [
            "↓let MyLet = 0",
            "enum Foo { case ↓MyEnum }"
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples +
            triggeringExamplesToRemove.map { $0.replacingOccurrences(of: "↓", with: "") }
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": false])
    }

    func testLinuxCrashOnEmojiNames() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamples = [
            "let 👦🏼 = \"👦🏼\""
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }
}
