@testable import SwiftLintBuiltInRules
import TestHelpers

final class GenericTypeNameRuleTests: SwiftLintTestCase {
    func testGenericTypeNameWithExcluded() {
        let baseDescription = GenericTypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("func foo<apple> {}"),
            Example("func foo<some_apple> {}"),
            Example("func foo<test123> {}"),
        ]
        let triggeringExamples = baseDescription.triggeringExamples + [
            Example("func foo<ap_ple> {}"),
            Example("func foo<appleJuice> {}"),
        ]
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
    }

    func testGenericTypeNameWithAllowedSymbols() {
        let baseDescription = GenericTypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("func foo<T$>() {}"),
            Example("func foo<T$, U%>(param: U%) -> T$ {}"),
            Example("typealias StringDictionary<T$> = Dictionary<String, T$>"),
            Example("class Foo<T$%> {}"),
            Example("struct Foo<T$%> {}"),
            Example("enum Foo<T$%> {}"),
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testGenericTypeNameWithAllowedSymbolsAndViolation() {
        let baseDescription = GenericTypeNameRule.description
        let triggeringExamples = [
            Example("func foo<↓T_$>() {}")
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testGenericTypeNameWithIgnoreStartWithLowercase() {
        let baseDescription = GenericTypeNameRule.description
        let triggeringExamplesToRemove = [
            Example("func foo<↓type>() {}"),
            Example("class Foo<↓type> {}"),
            Example("struct Foo<↓type> {}"),
            Example("enum Foo<↓type> {}"),
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples +
            triggeringExamplesToRemove.removingViolationMarkers()
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": false])
    }
}
