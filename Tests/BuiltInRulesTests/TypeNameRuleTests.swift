import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct TypeNameRuleTests {
    @Test
    func typeNameWithExcluded() {
        let baseDescription = TypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("class apple {}"),
            Example("struct some_apple {}"),
            Example("protocol test123 {}"),
        ]
        let triggeringExamples = baseDescription.triggeringExamples + [
            Example("enum ap_ple {}"),
            Example("typealias appleJuice = Void"),
        ]
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
    }

    @Test
    func typeNameWithAllowedSymbols() {
        let baseDescription = TypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("class MyType$ {}"),
            Example("struct MyType$ {}"),
            Example("enum MyType$ {}"),
            Example("typealias Foo$ = Void"),
            Example("protocol Foo {\n associatedtype Bar$\n }"),
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$"]])
    }

    @Test
    func typeNameWithAllowedSymbolsAndViolation() {
        let baseDescription = TypeNameRule.description
        let triggeringExamples = [
            Example("class ↓My_Type$ {}")
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    @Test
    func typeNameWithIgnoreStartWithLowercase() {
        let baseDescription = TypeNameRule.description
        let triggeringExamplesToRemove = [
            Example("private typealias ↓foo = Void"),
            Example("class ↓myType {}"),
            Example("struct ↓myType {}"),
            Example("enum ↓myType {}"),
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples +
            triggeringExamplesToRemove.removingViolationMarkers()
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": "off"])
    }
}
