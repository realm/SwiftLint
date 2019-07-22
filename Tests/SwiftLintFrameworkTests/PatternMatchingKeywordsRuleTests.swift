import SwiftLintFramework
import XCTest

class PatternMatchingKeywordsRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        verifyRule(PatternMatchingKeywordsRule.description)
    }

    func testWithZeroMaxDeclarations() {
        let nonTriggeringExamples = [
            "default",
            "case 1",
            "case bar",
            "case let (x)",
            "case let (x, y)",
            "case let .foo(x, y)",
            "case .foo(let x, var y)",
            "case var (x, y)",
            "case var .foo(x, y)"
        ].map(wrapInSwitch)
        let triggeringExamples = [
            "case .foo(↓let x)",
            "case .foo(↓let x), .bar(↓let x)",
            "case .foo(↓let x), let .bar(x)",
            "case .foo(↓var x)",
            "case .foo(↓let x, (↓let y, ↓let z))",
            "case .foo(↓let x, ↓let (y, z))",
            "case (↓let x,  ↓let y)",
            "case .foo(↓let x, ↓let y)",
            "case (.yamlParsing(↓let x), .yamlParsing(↓let y))",
            "case (↓var x,  ↓var y)",
            "case .foo(↓var x, ↓var y)",
            "case (.yamlParsing(↓var x), .yamlParsing(↓var y))"
        ].map(wrapInSwitch)

        let description = PatternMatchingKeywordsRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["max_declarations": 0])
    }
}

private func wrapInSwitch(_ str: String) -> String {
    return  "switch foo {\n" +
            "    \(str): break\n" +
            "}"
}
