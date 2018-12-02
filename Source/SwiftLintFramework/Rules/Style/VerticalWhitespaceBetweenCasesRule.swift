import Foundation
import SourceKittenFramework

private extension File {
    func violatingRanges(for pattern: String) -> [NSRange] {
        return match(pattern: pattern, excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    }
}

public struct VerticalWhitespaceBetweenCasesRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    private static let nonTriggeringExamples = [
        """
        switch x {

        case 0..<5:
            print("x is low")

        case 5..<10:
            print("x is high")

        default:
            print("x is invalid")

        }
        """,
        """
        switch x {
        case 0..<5:
            print("x is low")

        case 5..<10:
            print("x is high")

        default:
            print("x is invalid")
        }
        """,
        """
        switch x {
        case 0..<5: print("x is low")
        case 5..<10: print("x is high")
        default: print("x is invalid")
        }
        """
    ]

    private static let violatingToValidExamples: [String: String] = [
        """
            switch x {
            case 0..<5:
                print("x is valid")
        ↓    default:
                print("x is invalid")
            }
        """: """
            switch x {
            case 0..<5:
                print("x is valid")

            default:
                print("x is invalid")
            }
        """,
        """
            switch x {
            case .valid:
                print("x is valid")
        ↓    case .invalid:
                print("x is invalid")
            }
        """: """
            switch x {
            case .valid:
                print("x is valid")

            case .invalid:
                print("x is invalid")
            }
        """,
        """
            switch x {
            case .valid:
                print("multiple ...")
                print("... lines")
        ↓    case .invalid:
                print("multiple ...")
                print("... lines")
            }
        """: """
            switch x {
            case .valid:
                print("multiple ...")
                print("... lines")

            case .invalid:
                print("multiple ...")
                print("... lines")
            }
        """
    ]

    private let pattern = "([^\\n{][ \\t]*\\n)([ \\t]*(?:case[^\\n]+|default):[ \\t]*\\n)"
}

extension VerticalWhitespaceBetweenCasesRule: OptInRule, AutomaticTestableRule {
    public static let description = RuleDescription(
        identifier: "vertical_whitespace_between_cases",
        name: "Vertical Whitespace Between Cases",
        description: "Include a single empty line between switch cases.",
        kind: .style,
        nonTriggeringExamples: (violatingToValidExamples.values + nonTriggeringExamples).sorted(),
        triggeringExamples: Array(violatingToValidExamples.keys).sorted(),
        corrections: violatingToValidExamples.cleanedKeysDict()
    )

    public func validate(file: File) -> [StyleViolation] {
        let patternRegex = regex(pattern)
        return file.violatingRanges(for: pattern).compactMap { violationRange in
            let substring = file.contents.substring(from: violationRange.location, length: violationRange.length)
            let substringRange = NSRange(location: 0, length: substring.count)
            guard let matchResult = patternRegex.firstMatch(in: substring, options: [], range: substringRange) else {
                return nil
            }

            let violatingSubrange = matchResult.range(at: 2)
            let characterOffset = violationRange.location + violatingSubrange.location

            return StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: characterOffset)
            )
        }
    }
}

extension VerticalWhitespaceBetweenCasesRule: CorrectableRule {
    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: file.violatingRanges(for: pattern), for: self)
        guard !violatingRanges.isEmpty else { return [] }

        let patternRegex = regex(pattern)
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
