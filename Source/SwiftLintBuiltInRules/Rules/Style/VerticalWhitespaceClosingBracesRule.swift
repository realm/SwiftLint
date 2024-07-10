import Foundation
import SourceKittenFramework

struct VerticalWhitespaceClosingBracesRule: CorrectableRule, OptInRule {
    var configuration = VerticalWhitespaceClosingBracesConfiguration()

    static let description = RuleDescription(
        identifier: "vertical_whitespace_closing_braces",
        name: "Vertical Whitespace before Closing Braces",
        description: "Don't include vertical whitespace (empty line) before closing braces",
        kind: .style,
        nonTriggeringExamples: VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples.values.sorted() +
                               VerticalWhitespaceClosingBracesRuleExamples.nonTriggeringExamples,
        triggeringExamples: Array(VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples.keys.sorted()),
        corrections: VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples.removingViolationMarkers()
    )

    private let pattern = "((?:\\n[ \\t]*)+)(\\n[ \\t]*[)}\\]])"
    private let trivialLinePattern = "((?:\\n[ \\t]*)+)(\\n[ \\t)}\\]]*$)"

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = configuration.onlyEnforceBeforeTrivialLines ? self.trivialLinePattern : self.pattern

        let patternRegex: NSRegularExpression = regex(pattern)

        return file.violatingRanges(for: pattern).map { violationRange in
            let substring = file.contents.substring(from: violationRange.location, length: violationRange.length)
            let matchResult = patternRegex.firstMatch(in: substring, options: [], range: substring.fullNSRange)!
            let violatingSubrange = matchResult.range(at: 1)
            let characterOffset = violationRange.location + violatingSubrange.location + 1

            return StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severityConfiguration.severity,
                location: Location(file: file, characterOffset: characterOffset)
            )
        }
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        let pattern = configuration.onlyEnforceBeforeTrivialLines ? self.trivialLinePattern : self.pattern

        let violatingRanges = file.ruleEnabled(violatingRanges: file.violatingRanges(for: pattern), for: self)
        guard violatingRanges.isNotEmpty else { return [] }

        let patternRegex: NSRegularExpression = regex(pattern)
        let replacementTemplate = "$2"
        let description = Self.description

        var corrections = [Correction]()
        var fileContents = file.contents

        for violationRange in violatingRanges.reversed() {
            fileContents = patternRegex.stringByReplacingMatches(
                in: fileContents,
                options: [],
                range: violationRange,
                withTemplate: replacementTemplate
            )

            let location = Location(file: file, characterOffset: violationRange.location)
            let correction = Correction(ruleDescription: description, location: location)
            corrections.append(correction)
        }

        file.write(fileContents)
        return corrections
    }
}

private extension SwiftLintFile {
    func violatingRanges(for pattern: String) -> [NSRange] {
        match(pattern: pattern, excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    }
}
