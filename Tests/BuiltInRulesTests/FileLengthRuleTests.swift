import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct FileLengthRuleTests {
    @Test
    func fileLengthWithDefaultConfiguration() {
        verifyRule(FileLengthRule.description, commentDoesntViolate: false,
                   testMultiByteOffsets: false, testShebang: false)
    }

    @Test
    func fileLengthIgnoringLinesWithOnlyComments() {
        let triggeringExamples = #examples([
            repeatElement("print(\"swiftlint\")\n", count: 401).joined().asExample()
        ])
        let nonTriggeringExamples = #examples([
            (repeatElement("print(\"swiftlint\")\n", count: 400) + ["//\n"]).joined().asExample(),
            repeatElement("print(\"swiftlint\")\n", count: 400).joined().asExample(),
            repeatElement("print(\"swiftlint\")\n\n", count: 201).joined().asExample(),
        ])

        let description = FileLengthRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignore_comment_only_lines": true],
                   testMultiByteOffsets: false, testShebang: false)
    }
}
