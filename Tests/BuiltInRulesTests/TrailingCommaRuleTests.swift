import Foundation
import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct TrailingCommaRuleTests {
    @Test
    func trailingCommaRuleWithDefaultConfiguration() {
        // Verify TrailingCommaRule with test values for when mandatory_comma is false (default).
        let triggeringExamples = TrailingCommaRule.description.triggeringExamples +
        #examples(["class C {\n #if true\n func f() {\n let foo = [1, 2, 3↓,]\n }\n #endif\n}"])
        verifyRule(TrailingCommaRule.description.with(triggeringExamples: triggeringExamples))

        // Ensure the rule produces the correct reason string.
        let failingCase = Example("let array = [\n\t1,\n\t2,\n]\n")
        #expect(
            trailingCommaViolations(failingCase).first?.reason == "Collection literals should not have trailing commas")
    }

    private static let triggeringExamples = #examples([
        "let foo = [1, 2,\n 3↓]\n",
        "let foo = [1: 2,\n 2: 3↓]\n",
        "let foo = [1: 2,\n 2: 3↓   ]\n",
        "struct Bar {\n let foo = [1: 2,\n 2: 3↓]\n}\n",
        "let foo = [1, 2,\n 3↓] + [4,\n 5, 6↓]\n",
        "let foo = [1, 2,\n 3↓  ]",
        "let foo = [\"אבג\", \"αβγ\",\n\"🇺🇸\"↓]\n",
    ])

    private static let nonTriggeringExamples = #examples([
        "let foo = []\n",
        "let foo = [:]\n",
        "let foo = [1, 2, 3,]\n",
        "let foo = [1, 2, 3, ]\n",
        "let foo = [1, 2, 3   ,]\n",
        "let foo = [1: 2, 2: 3, ]\n",
        "struct Bar {\n let foo = [1: 2, 2: 3,]\n}\n",
        "let foo = [Void]()\n",
        "let foo = [(Void, Void)]()\n",
        "let foo = [1, 2, 3]\n",
        "let foo = [1: 2, 2: 3]\n",
        "let foo = [1: 2, 2: 3   ]\n",
        "struct Bar {\n let foo = [1: 2, 2: 3]\n}\n",
        "let foo = [1, 2, 3] + [4, 5, 6]\n",
    ])

    private static let corrections: [Example: Example] = {
        let fixed = triggeringExamples.map { $0.with(code: $0.code.replacingOccurrences(of: "↓", with: ",")) }
        var result: [Example: Example] = [:]
        for (triggering, correction) in zip(triggeringExamples, fixed) {
            result[triggering] = correction
        }
        return result
    }()

    private let mandatoryCommaRuleDescription = TrailingCommaRule.description
        .with(nonTriggeringExamples: Self.nonTriggeringExamples)
        .with(triggeringExamples: Self.triggeringExamples)
        .with(corrections: Self.corrections)

    @Test
    func trailingCommaRuleWithMandatoryComma() {
        // Verify TrailingCommaRule with test values for when mandatory_comma is true.
        let ruleDescription = mandatoryCommaRuleDescription
        let ruleConfiguration = ["mandatory_comma": true]

        verifyRule(ruleDescription, ruleConfiguration: ruleConfiguration)

        // Ensure the rule produces the correct reason string.
        let failingCase = Example("let array = [\n\t1,\n\t2\n]\n")
        #expect(
            trailingCommaViolations(failingCase, ruleConfiguration: ruleConfiguration).first?.reason
                == "Multi-line collection literals should have trailing commas")
    }

    private func trailingCommaViolations(_ example: Example, ruleConfiguration: Any? = nil) -> [StyleViolation] {
        let config = makeConfig(ruleConfiguration, TrailingCommaRule.identifier)!
        return violations(example, config: config)
    }
}
