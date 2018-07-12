import Foundation
import SourceKittenFramework

private extension File {
    func violatingRanges(for pattern: String) -> [NSRange] {
        return match(pattern: pattern, excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    }
}

public struct VerticalWhitespaceOpeningBracesRule {
    public init() {}

    private static let nonTriggeringExamples = [
        "[1, 2].map { $0 }.foo()",
        "[1, 2].map { $0 }.filter { num in",
        "// [1, 2].map { $0 }.filter { num in",
        """
        /*
            class X {

                let x = 5

            }
        */
        """
    ]

    private static let violatingToValidExamples: [String: String] = [
        "if x == 5 {\n\n    print(\"x is 5\")": "if x == 5 {\n    print(\"x is 5\")",
        "if x == 5 {\n\n\n    print(\"x is 5\")": "if x == 5 {\n    print(\"x is 5\")",
        "if x == 5 {\n\n  print(\"x is 5\")": "if x == 5 {\n  print(\"x is 5\")",
        "if x == 5 {\n\n\tprint(\"x is 5\")": "if x == 5 {\n\tprint(\"x is 5\")",
        "struct MyStruct {\n\n    let x = 5": "struct MyStruct {\n    let x = 5",
        "struct MyStruct {\n\n  let x = 5": "struct MyStruct {\n  let x = 5",
        "struct MyStruct {\n\n\tlet x = 5": "struct MyStruct {\n\tlet x = 5",
        "class X {\n    struct Y {\n\n    class Z {\n": "class X {\n    struct Y {\n    class Z {\n",
        "[\n\n1,\n2,\n3\n]": "[\n1,\n2,\n3\n]",
        "foo(\n\nx: 5,\ny:6\n)": "foo(\nx: 5,\ny:6\n)"
    ]

    private let pattern = "([{(\\[][ \\t]*)((?:\\n[ \\t]*)+)(\\n)"
}

extension VerticalWhitespaceOpeningBracesRule: OptInRule {
    public var configurationDescription: String { return "N/A" }

    public init(configuration: Any) throws {}

    public static let description = RuleDescription(
        identifier: "vertical_whitespace_opening_braces",
        name: "Vertical Whitespace after Opening Braces",
        description: "Don't include vertical whitespace (empty line) after opening braces.",
        kind: .style,
        nonTriggeringExamples: Array(Set(violatingToValidExamples.values)) + nonTriggeringExamples,
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

extension VerticalWhitespaceOpeningBracesRule: CorrectableRule {
    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: file.violatingRanges(for: pattern), for: self)
        guard !violatingRanges.isEmpty else { return [] }

        let patternRegex: NSRegularExpression = regex(pattern)
        let replacementTemplate = "$1$3"
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
