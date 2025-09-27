import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct CyclomaticComplexityRuleTests {
    private static let complexSwitchExample: Example = {
        var example = "func switcheroo() {\n"
        example += "    switch foo {\n"
        for index in (0...30) {
            example += "  case \(index):   print(\"\(index)\")\n"
        }
        example += "    }\n"
        example += "}\n"
        return Example(example)
    }()

    private static let complexSwitchInitExample: Example = {
        var example = "init() {\n"
        example += "    switch foo {\n"
        for index in (0...30) {
            example += "  case \(index):   print(\"\(index)\")\n"
        }
        example += "    }\n"
        example += "}\n"
        return Example(example)
    }()

    private static let complexIfExample: Example = {
        let nest = 22
        var example = "func nestThoseIfs() {\n"
        for index in (0...nest) {
            let indent = String(repeating: "    ", count: index + 1)
            example += indent + "if false != true {\n"
            example += indent + "   print \"\\(i)\"\n"
        }

        for index in (0...nest).reversed() {
            let indent = String(repeating: "    ", count: index + 1)
            example += indent + "}\n"
        }
        example += "}\n"
        return Example(example)
    }()

    @Test
    func cyclomaticComplexity() {
        verifyRule(CyclomaticComplexityRule.description, commentDoesntViolate: true, stringDoesntViolate: true)
    }

    @Test
    func ignoresCaseStatementsConfigurationEnabled() {
        let baseDescription = CyclomaticComplexityRule.description
        let triggeringExamples = [Self.complexIfExample]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [Self.complexSwitchExample]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_case_statements": true],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }

    @Test
    func ignoresCaseStatementsConfigurationDisabled() {
        let baseDescription = CyclomaticComplexityRule.description
        let triggeringExamples = baseDescription.triggeringExamples + [
            Self.complexSwitchExample,
            Self.complexSwitchInitExample,
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_case_statements": false],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }
}
