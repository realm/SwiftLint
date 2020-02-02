import Foundation
import SourceKittenFramework

private extension SwiftLintFile {
    func violatingRanges(for pattern: String) -> [NSRange] {
        return match(pattern: pattern, excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    }
}

public struct VerticalWhitespaceClosingBracesRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    private static let nonTriggeringExamples: [Example] = [
        Example("[1, 2].map { $0 }.filter {"),
        Example("[1, 2].map { $0 }.filter { num in"),
        Example("""
        /*
            class X {

                let x = 5

            }
        */
        """)
    ]

    private static let violatingToValidExamples: [Example: Example] = [
        Example("    print(\"x is 5\")\n↓\n}"): Example("    print(\"x is 5\")\n}"),
        Example("    print(\"x is 5\")\n↓\n\n}"): Example("    print(\"x is 5\")\n}"),
        Example("    print(\"x is 5\")\n↓    \n}"): Example("    print(\"x is 5\")\n}"),
        Example("        )\n}\n↓\n    }\n}"): Example("        )\n}\n    }\n}"),
        Example("[\n1,\n2,\n3\n↓\n]"): Example("[\n1,\n2,\n3\n]"),
        Example("foo(\nx: 5,\ny:6\n↓\n)"): Example("foo(\nx: 5,\ny:6\n)"),
        Example("class Name {\n    run(5) { x in print(x) }\n↓\n}"):
            Example("class Name {\n    run(5) { x in print(x) }\n}")
    ]

    private let pattern = "((?:\\n[ \\t]*)+)(\\n[ \\t]*[)}\\]])"
}

extension VerticalWhitespaceClosingBracesRule: OptInRule, AutomaticTestableRule {
    public var configurationDescription: String { return "N/A" }

    public init(configuration: Any) throws {}

    public static let description = RuleDescription(
        identifier: "vertical_whitespace_closing_braces",
        name: "Vertical Whitespace before Closing Braces",
        description: "Don't include vertical whitespace (empty line) before closing braces.",
        kind: .style,
        nonTriggeringExamples: (violatingToValidExamples.values + nonTriggeringExamples).sorted(),
        triggeringExamples: Array(violatingToValidExamples.keys).sorted(),
        corrections: violatingToValidExamples.removingViolationMarkers()
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let patternRegex: NSRegularExpression = regex(pattern)

        return file.violatingRanges(for: pattern).map { violationRange in
            let substring = file.contents.substring(from: violationRange.location, length: violationRange.length)
            let matchResult = patternRegex.firstMatch(in: substring, options: [], range: substring.fullNSRange)!
            let violatingSubrange = matchResult.range(at: 1)
            let characterOffset = violationRange.location + violatingSubrange.location + 1

            return StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: characterOffset)
            )
        }
    }
}

extension VerticalWhitespaceClosingBracesRule: CorrectableRule {
    public func correct(file: SwiftLintFile) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: file.violatingRanges(for: pattern), for: self)
        guard !violatingRanges.isEmpty else { return [] }

        let patternRegex: NSRegularExpression = regex(pattern)
        let replacementTemplate = "$2"
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
