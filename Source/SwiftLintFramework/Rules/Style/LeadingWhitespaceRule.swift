import Foundation
import SourceKittenFramework

public struct LeadingWhitespaceRule: CorrectableRule, ConfigurationProviderRule, SourceKitFreeRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "leading_whitespace",
        name: "Leading Whitespace",
        description: "Files should not contain leading whitespace.",
        kind: .style,
        nonTriggeringExamples: [ Example("//\n") ],
        triggeringExamples: [ Example("\n"), Example(" //\n") ],
        corrections: [Example("\n //"): Example("//")]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
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

    public func correct(file: SwiftLintFile) -> [Correction] {
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
