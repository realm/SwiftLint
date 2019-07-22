import SwiftLintFramework
import XCTest

class PatternMatchingKeywordsRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        verifyRule(PatternMatchingKeywordsRule.description)
    }

    func testWithZeroMaxDeclarations() {
        let nonTriggeringExamples = [
            Example("default"),
            Example("case 1"),
            Example("case bar"),
            Example("case let (x)"),
            Example("case let (x, y)"),
            Example("case let .foo(x, y)"),
            Example("case .foo(let x, var y)"),
            Example("case var (x, y)"),
            Example("case var .foo(x, y)")
        ].map(wrapInSwitch)
        let triggeringExamples = [
            Example("case .foo(↓let x)"),
            Example("case .foo(↓let x), .bar(↓let x)"),
            Example("case .foo(↓let x), let .bar(x)"),
            Example("case .foo(↓var x)"),
            Example("case .foo(↓let x, (↓let y, ↓let z))"),
            Example("case .foo(↓let x, ↓let (y, z))"),
            Example("case (↓let x,  ↓let y)"),
            Example("case .foo(↓let x, ↓let y)"),
            Example("case (.yamlParsing(↓let x), .yamlParsing(↓let y))"),
            Example("case (↓var x,  ↓var y)"),
            Example("case .foo(↓var x, ↓var y)"),
            Example("case (.yamlParsing(↓var x), .yamlParsing(↓var y))"),
            Example("case (↓let .yamlParsing(x), ↓let .yamlParsing(y))")
        ].map(wrapInSwitch)

        let description = PatternMatchingKeywordsRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["max_declarations": 0])
    }
}

private func wrapInSwitch(_ example: Example) -> Example {
    return example.with(code: """
        switch foo {
            \(example.code): break
        }
        """)
}
