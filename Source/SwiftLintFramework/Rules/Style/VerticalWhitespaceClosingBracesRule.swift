import Foundation
import SourceKittenFramework

private extension SwiftLintFile {
    func violatingRanges(for pattern: String) -> [NSRange] {
        return match(pattern: pattern, excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    }
}

struct VerticalWhitespaceClosingBracesRule: ConfigurationProviderRule {
    var configuration = Configuration()

    init() {}

    private let pattern = "((?:\\n[ \\t]*)+)(\\n[ \\t]*[)}\\]])"
    private let trivialLinePattern = "((?:\\n[ \\t]*)+)(\\n[ \\t)}\\]]*$)"
}

extension VerticalWhitespaceClosingBracesRule {
    private enum ConfigurationKey: String {
        case severity = "severity"
        case onlyEnforceBeforeTrivialLines = "only_enforce_before_trivial_lines"
    }

    struct Configuration: RuleConfiguration, Equatable {
        private(set) var severityConfiguration = SeverityConfiguration(.warning)
        private(set) var onlyEnforceBeforeTrivialLines = false

        var consoleDescription: String {
            return severityConfiguration.consoleDescription +
                ", \(ConfigurationKey.onlyEnforceBeforeTrivialLines.rawValue): \(onlyEnforceBeforeTrivialLines)"
        }

        mutating func apply(configuration: Any) throws {
            let error = ConfigurationError.unknownConfiguration

            guard let configuration = configuration as? [String: Any] else {
                throw error
            }

            for (string, value) in configuration {
                guard let key = ConfigurationKey(rawValue: string) else {
                    throw error
                }

                switch (key, value) {
                case (.severity, let stringValue as String):
                    try severityConfiguration.apply(configuration: stringValue)
                case (.onlyEnforceBeforeTrivialLines, let boolValue as Bool):
                    onlyEnforceBeforeTrivialLines = boolValue
                default:
                    throw error
                }
            }
        }
    }
}

extension VerticalWhitespaceClosingBracesRule: OptInRule {
    var configurationDescription: String { return "N/A" }

    private static let examples = VerticalWhitespaceClosingBracesRuleExamples.self
    static let description = RuleDescription(
        identifier: "vertical_whitespace_closing_braces",
        name: "Vertical Whitespace before Closing Braces",
        description: "Don't include vertical whitespace (empty line) before closing braces.",
        kind: .style,
        nonTriggeringExamples: (examples.violatingToValidExamples.values +
                                examples.nonTriggeringExamples),
        triggeringExamples: Array(examples.violatingToValidExamples.keys),
        corrections: examples.violatingToValidExamples.removingViolationMarkers()
    )

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
}

extension VerticalWhitespaceClosingBracesRule: CorrectableRule {
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
