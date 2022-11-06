@testable import SwiftLintBuiltInRules
import SwiftLintFramework

class CyclomaticComplexityRuleTests: SwiftLintTestCase {
    private lazy var complexSwitchExample: Example = {
        var example = "func switcheroo() {\n"
        example += "    switch foo {\n"
        for index in (0...30) {
            example += "  case \(index):   print(\"\(index)\")\n"
        }
        example += "    }\n"
        example += "}\n"
        return Example(example)
    }()

    private lazy var complexIfExample: Example = {
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

    func testCyclomaticComplexity() {
        verifyRule(CyclomaticComplexityRule.description, commentDoesntViolate: true, stringDoesntViolate: true)
    }

    func testIgnoresCaseStatementsConfigurationEnabled() {
        let baseDescription = CyclomaticComplexityRule.description
        let triggeringExamples = [complexIfExample]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [complexSwitchExample]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_case_statements": true],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }

    func testIgnoresCaseStatementsConfigurationDisabled() {
        let baseDescription = CyclomaticComplexityRule.description
        let triggeringExamples = baseDescription.triggeringExamples + [complexSwitchExample]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_case_statements": false],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }
}
