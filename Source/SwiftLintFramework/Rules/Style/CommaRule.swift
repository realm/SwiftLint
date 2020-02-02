import Foundation
import SourceKittenFramework

public struct CommaRule: SubstitutionCorrectableRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "comma",
        name: "Comma Spacing",
        description: "There should be no space before and one after any comma.",
        kind: .style,
        nonTriggeringExamples: [
            Example("func abc(a: String, b: String) { }"),
            Example("abc(a: \"string\", b: \"string\""),
            Example("enum a { case a, b, c }"),
            Example("func abc(\n  a: String,  // comment\n  bcd: String // comment\n) {\n}\n"),
            Example("func abc(\n  a: String,\n  bcd: String\n) {\n}\n"),
            Example("#imageLiteral(resourceName: \"foo,bar,baz\")")
        ],
        triggeringExamples: [
            Example("func abc(a: String↓ ,b: String) { }"),
            Example("func abc(a: String↓ ,b: String↓ ,c: String↓ ,d: String) { }"),
            Example("abc(a: \"string\"↓,b: \"string\""),
            Example("enum a { case a↓ ,b }"),
            Example("let result = plus(\n    first: 3↓ , // #683\n    second: 4\n)\n")
        ],
        corrections: [
            Example("func abc(a: String↓,b: String) {}\n"): Example("func abc(a: String, b: String) {}\n"),
            Example("abc(a: \"string\"↓,b: \"string\"\n"): Example("abc(a: \"string\", b: \"string\"\n"),
            Example("abc(a: \"string\"↓  ,  b: \"string\"\n"): Example("abc(a: \"string\", b: \"string\"\n"),
            Example("enum a { case a↓  ,b }\n"): Example("enum a { case a, b }\n"),
            Example("let a = [1↓,1]\nlet b = 1\nf(1, b)\n"): Example("let a = [1, 1]\nlet b = 1\nf(1, b)\n"),
            Example("let a = [1↓,1↓,1↓,1]\n"): Example("let a = [1, 1, 1, 1]\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, ", ")
    }

    // captures spaces and comma only
    // http://userguide.icu-project.org/strings/regexp

    private static let mainPatternGroups =
        "(" +                  // start first capure
        "\\s+" +               // followed by whitespace
        "," +                  // to the left of a comma
        "[\\t\\p{Z}]*" +       // followed by any amount of tab or space.
        "|" +                  // or
        "," +                  // immediately followed by a comma
        "(?:[\\t\\p{Z}]{0}|" + // followed by 0
        "[\\t\\p{Z}]{2,})" +   // or 2+ tab or space characters.
        ")" +                  // end capture
        "(\\S)"                // second capture is not whitespace.

    private static let pattern =
        "\\S\(mainPatternGroups)" + // Regexp will match if expression not begin with comma
        "|" +                       // or
        "\(mainPatternGroups)"      // Regexp will match if expression begins with comma

    private static let regularExpression = regex(pattern, options: [])
    private static let excludingSyntaxKindsForFirstCapture = SyntaxKind.commentAndStringKinds.union([.objectLiteral])
    private static let excludingSyntaxKindsForSecondCapture = SyntaxKind.commentKinds.union([.objectLiteral])

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let contents = file.stringView
        let range = contents.range
        let syntaxMap = file.syntaxMap
        return CommaRule.regularExpression
            .matches(in: contents, options: [], range: range)
            .compactMap { match -> NSRange? in
                if match.numberOfRanges != 5 { return nil } // Number of Groups in regexp

                var indexStartRange = 1
                if match.range(at: indexStartRange).location == NSNotFound {
                    indexStartRange += 2
                }

                // check first captured range
                let firstRange = match.range(at: indexStartRange)
                guard let matchByteFirstRange = contents
                    .NSRangeToByteRange(start: firstRange.location, length: firstRange.length)
                    else { return nil }

                // first captured range won't match kinds if it is not comment neither string
                let firstCaptureIsCommentOrString = syntaxMap.kinds(inByteRange: matchByteFirstRange)
                    .contains(where: CommaRule.excludingSyntaxKindsForFirstCapture.contains)
                if firstCaptureIsCommentOrString {
                    return nil
                }

                // If the first range does not start with comma, it already violates this rule
                // no matter what is contained in the second range.
                if !contents.substring(with: firstRange).hasPrefix(", ") {
                    return firstRange
                }

                // check second captured range
                let secondRange = match.range(at: indexStartRange + 1)
                guard let matchByteSecondRange = contents
                    .NSRangeToByteRange(start: secondRange.location, length: secondRange.length)
                    else { return nil }

                // second captured range won't match kinds if it is not comment
                let secondCaptureIsComment = syntaxMap.kinds(inByteRange: matchByteSecondRange)
                    .contains(where: CommaRule.excludingSyntaxKindsForSecondCapture.contains)
                if secondCaptureIsComment {
                    return nil
                }

                // return first captured range
                return firstRange
            }
    }
}
