import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

private func funcWithParameters(_ parameters: String,
                                violates: Bool = false,
                                file: StaticString = #filePath,
                                line: UInt = #line) -> Example {
    let marker = violates ? "↓" : ""

    return Example("func \(marker)abc(\(parameters)) {}\n", file: file, line: line)
}

@Suite(.rulesRegistered)
struct FunctionParameterCountRuleTests {
    @Test
    func functionParameterCount() {
        let baseDescription = FunctionParameterCountRule.description
        let nonTriggeringExamples = [
            funcWithParameters(repeatElement("x: Int, ", count: 3).joined() + "x: Int")
        ]

        let triggeringExamples = [
            funcWithParameters(repeatElement("x: Int, ", count: 5).joined() + "x: Int")
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description)
    }

    @Test
    func defaultFunctionParameterCount() {
        let baseDescription = FunctionParameterCountRule.description
        let nonTriggeringExamples = [
            funcWithParameters(repeatElement("x: Int, ", count: 3).joined() + "x: Int")
        ]

        let defaultParams = repeatElement("x: Int = 0, ", count: 2).joined() + "x: Int = 0"
        let triggeringExamples = [
            funcWithParameters(repeatElement("x: Int, ", count: 3).joined() + defaultParams)
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_default_parameters": false])
    }
}
