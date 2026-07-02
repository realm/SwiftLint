import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct TypeNameRuleTests {
    @Test
    func typeNameWithExcluded() {
        let baseDescription = TypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + #examples([
            "class apple {}",
            "struct some_apple {}",
            "protocol test123 {}",
        ])
        let triggeringExamples = baseDescription.triggeringExamples + #examples([
            "enum ap_ple {}",
            "typealias appleJuice = Void",
        ])
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
    }

    @Test
    func typeNameWithAllowedSymbols() {
        let baseDescription = TypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + #examples([
            "class MyType$ {}",
            "struct MyType$ {}",
            "enum MyType$ {}",
            "typealias Foo$ = Void",
            "protocol Foo {\n associatedtype Bar$\n }",
        ])

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$"]])
    }

    @Test
    func typeNameWithAllowedSymbolsAndViolation() {
        let baseDescription = TypeNameRule.description
        let triggeringExamples = #examples([
            "class ↓My_Type$ {}"
        ])

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    @Test
    func typeNameWithIgnoreStartWithLowercase() {
        let baseDescription = TypeNameRule.description
        let triggeringExamplesToRemove = #examples([
            "private typealias ↓foo = Void",
            "class ↓myType {}",
            "struct ↓myType {}",
            "enum ↓myType {}",
        ])
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples +
            triggeringExamplesToRemove.removingViolationMarkers()
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": "off"])
    }
}
