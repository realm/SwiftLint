import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct GenericTypeNameRuleTests {
    @Test
    func genericTypeNameWithExcluded() {
        let baseDescription = GenericTypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + #examples([
            "func foo<apple> {}",
            "func foo<some_apple> {}",
            "func foo<test123> {}",
        ])
        let triggeringExamples = baseDescription.triggeringExamples + #examples([
            "func foo<ap_ple> {}",
            "func foo<appleJuice> {}",
        ])
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
    }

    @Test
    func genericTypeNameWithAllowedSymbols() {
        let baseDescription = GenericTypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + #examples([
            "func foo<T$>() {}",
            "func foo<T$, U%>(param: U%) -> T$ {}",
            "typealias StringDictionary<T$> = Dictionary<String, T$>",
            "class Foo<T$%> {}",
            "struct Foo<T$%> {}",
            "enum Foo<T$%> {}",
        ])

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    @Test
    func genericTypeNameWithAllowedSymbolsAndViolation() {
        let baseDescription = GenericTypeNameRule.description
        let triggeringExamples = #examples([
            "func foo<↓T_$>() {}"
        ])

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    @Test
    func genericTypeNameWithIgnoreStartWithLowercase() {
        let baseDescription = GenericTypeNameRule.description
        let triggeringExamplesToRemove = #examples([
            "func foo<↓type>() {}",
            "class Foo<↓type> {}",
            "struct Foo<↓type> {}",
            "enum Foo<↓type> {}",
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
