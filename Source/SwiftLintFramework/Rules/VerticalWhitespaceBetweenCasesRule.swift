import Foundation
import SourceKittenFramework

private extension File {
    func violatingRanges(for pattern: String) -> [NSRange] {
        return match(pattern: pattern, excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    }
}

public struct VerticalWhitespaceBetweenCasesRule {
    public init() {}

    private static let violatingToValidExamples: [String: String] = [
    """
        switch x {
        case 0..<5:
            print("x is valid")
        default:
            print("x is invalid")
        }
    """: """
        switch x {
        case 0..<5:
            print("x is valid")

        default:
            print("x is invalid")
        }
    """
    ]

    private let pattern = "([^\\n{][ \\t]*\\n)([ \\t]*(?:case[^\\n]+|default):[ \\t]*\\n)"
}

extension VerticalWhitespaceBetweenCasesRule: OptInRule {
    public var configurationDescription: String { return "N/A" }

    public init(configuration: Any) throws {}

    public static let description = RuleDescription(
        identifier: "vertical_whitespace_between_cases",
        name: "Vertical Whitespace Between Cases",
        description: "Include a vertical whitespace (empty line) between cases in switch statements.",
        kind: .style,
        nonTriggeringExamples: Array(Set(violatingToValidExamples.values)),
        triggeringExamples: Array(Set(violatingToValidExamples.keys)),
        corrections: violatingToValidExamples
    )

    public func validate(file: File) -> [StyleViolation] {
        return file.violatingRanges(for: pattern).map {
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: ViolationSeverity.warning,
                location: Location(file: file, characterOffset: $0.location)
            )
        }
    }
}

extension VerticalWhitespaceBetweenCasesRule: CorrectableRule {
    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: file.violatingRanges(for: pattern), for: self)
        guard !violatingRanges.isEmpty else { return [] }

        let patternRegex: NSRegularExpression = regex(pattern)
        let replacementTemplate = "$1\n$2"
        let description = type(of: self).description

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
