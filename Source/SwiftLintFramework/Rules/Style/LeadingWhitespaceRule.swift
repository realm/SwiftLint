import Foundation
import SourceKittenFramework

struct LeadingWhitespaceRule: CorrectableRule, ConfigurationProviderRule, SourceKitFreeRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "leading_whitespace",
        name: "Leading Whitespace",
        description: "Files should not contain leading whitespace.",
        kind: .style,
        nonTriggeringExamples: [
            Example("//\n")
        ],
        triggeringExamples: [
            Example("\n//\n"),
            Example(" //\n")
        ].skipMultiByteOffsetTests().skipDisableCommandTests(),
        corrections: [
            Example("\n //", testMultiByteOffsets: false): Example("//")
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let countOfLeadingWhitespace = file.contents.countOfLeadingCharacters(in: .whitespacesAndNewlines)
        if countOfLeadingWhitespace == 0 {
            return []
        }

        let reason = "File shouldn't start with whitespace: " +
                     "currently starts with \(countOfLeadingWhitespace) whitespace characters"

        return [StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file.path, line: 1),
                               reason: reason)]
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        let whitespaceAndNewline = CharacterSet.whitespacesAndNewlines
        let spaceCount = file.contents.countOfLeadingCharacters(in: whitespaceAndNewline)
        guard spaceCount > 0,
            let firstLineRange = file.lines.first?.range,
            file.ruleEnabled(violatingRanges: [firstLineRange], for: self).isNotEmpty else {
                return []
        }

        let indexEnd = file.contents.index(
            file.contents.startIndex,
            offsetBy: spaceCount,
            limitedBy: file.contents.endIndex) ?? file.contents.endIndex
        file.write(String(file.contents[indexEnd...]))
        let location = Location(file: file.path, line: max(file.lines.count, 1))
        return [Correction(ruleDescription: Self.description, location: location)]
    }
}
