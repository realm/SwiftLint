import SwiftLintFramework
import XCTest

class FileLengthRuleConfigurationTests: XCTestCase {
    func testFileLengthWithDefaultConfiguration() async {
        await verifyRule(FileLengthRule.description, commentDoesntViolate: false,
                         testMultiByteOffsets: false, testShebang: false)
    }

    func testFileLengthIgnoringLinesWithOnlyComments() async {
        let triggeringExamples = [
            Example(repeatElement("print(\"swiftlint\")\n", count: 401).joined())
        ]
        let nonTriggeringExamples = [
            Example((repeatElement("print(\"swiftlint\")\n", count: 400) + ["//\n"]).joined()),
            Example(repeatElement("print(\"swiftlint\")\n", count: 400).joined()),
            Example(repeatElement("print(\"swiftlint\")\n\n", count: 201).joined())
        ]

        let description = FileLengthRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        await verifyRule(description, ruleConfiguration: ["ignore_comment_only_lines": true],
                         testMultiByteOffsets: false, testShebang: false)
    }
}
