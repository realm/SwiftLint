@testable import SwiftLintFramework
import XCTest

class GenericTypeNameRuleTests: XCTestCase {
    func testGenericTypeNameWithExcluded() {
        let baseDescription = GenericTypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("func foo<apple> {}\n"),
            Example("func foo<some_apple> {}\n"),
            Example("func foo<test123> {}\n")
        ]
        let triggeringExamples = baseDescription.triggeringExamples + [
            Example("func foo<ap_ple> {}\n"),
            Example("func foo<appleJuice> {}\n")
        ]
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
    }

    func testGenericTypeNameWithAllowedSymbols() {
        let baseDescription = GenericTypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("func foo<T$>() {}\n"),
            Example("func foo<T$, U%>(param: U%) -> T$ {}\n"),
            Example("typealias StringDictionary<T$> = Dictionary<String, T$>\n"),
            Example("class Foo<T$%> {}\n"),
            Example("struct Foo<T$%> {}\n"),
            Example("enum Foo<T$%> {}\n")
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testGenericTypeNameWithAllowedSymbolsAndViolation() {
        let baseDescription = GenericTypeNameRule.description
        let triggeringExamples = [
            Example("func foo<↓T_$>() {}\n")
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testGenericTypeNameWithIgnoreStartWithLowercase() {
        let baseDescription = GenericTypeNameRule.description
        let triggeringExamplesToRemove = [
            Example("func foo<↓type>() {}\n"),
            Example("class Foo<↓type> {}\n"),
            Example("struct Foo<↓type> {}\n"),
            Example("enum Foo<↓type> {}\n")
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
