import SwiftLintFramework
import XCTest

class TypeNameRuleTests: XCTestCase {
    func testTypeName() {
        verifyRule(TypeNameRule.description)
    }

    func testTypeNameWithAllowedSymbols() {
        let baseDescription = TypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("class MyType$ {}"),
            Example("struct MyType$ {}"),
            Example("enum MyType$ {}"),
            Example("typealias Foo$ = Void"),
            Example("protocol Foo {\n associatedtype Bar$\n }")
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$"]])
    }

    func testTypeNameWithAllowedSymbolsAndViolation() {
        let baseDescription = TypeNameRule.description
        let triggeringExamples = [
            Example("class ↓My_Type$ {}")
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testTypeNameWithIgnoreStartWithLowercase() {
        let baseDescription = TypeNameRule.description
        let triggeringExamplesToRemove = [
            Example("private typealias ↓foo = Void"),
            Example("class ↓myType {}"),
            Example("struct ↓myType {}"),
            Example("enum ↓myType {}")
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
