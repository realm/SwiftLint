import Foundation
import SourceKittenFramework

public struct CommentSpacingRule: OptInRule, ConfigurationProviderRule, SubstitutionCorrectableRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "comment_spacing",
        name: "Comment Spacing",
        description: "Prefer at least one space after slashes for comments.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            // This is a comment
            """),
            Example("""
            /// Triple slash comment
            """),
            Example("""
            // Multiline double-slash
            // comment
            """),
            Example("""
            /// Multiline triple-slash
            /// comment
            """),
            Example("""
            /// Multiline triple-slash
            ///   - This is indented
            """),
            Example("""
            // - MARK: Mark comment
            """),
            Example("""
            /* Asterisk comment */
            """),
            Example("""
            /*
                Multiline asterisk comment
            */
            """)
        ],
        triggeringExamples: [
            Example("""
            //↓Something
            """),
            Example("""
            //↓MARK
            """),
            Example("""
            //↓👨‍👨‍👦‍👦Something
            """),
            Example("""
            func a() {
                //↓This needs refactoring
                print("Something")
            }
            //↓We should improve above function
            """),
            Example("""
            ///↓This is a comment
            """),
            Example("""
            /// Multiline triple-slash
            ///↓This line is incorrect, though
            """),
            Example("""
            //↓- MARK: Mark comment
            """)
        ],
        corrections: [
            Example("//↓Something"): Example("// Something"),
            Example("//↓- MARK: Mark comment"): Example("// - MARK: Mark comment"),
            Example("""
            /// Multiline triple-slash
            ///↓This line is incorrect, though
            """): Example("""
            /// Multiline triple-slash
            /// This line is incorrect, though
            """),
            Example("""
            func a() {
                //↓This needs refactoring
                print("Something")
            }
            //↓We should improve above function
            """): Example("""
            func a() {
                // This needs refactoring
                print("Something")
            }
            // We should improve above function
            """)
        ]
    )

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        // Find all comment tokens in the file and regex search them for violations
        let commentTokens = file.syntaxMap.tokens.filter { SyntaxKind.commentKinds.contains($0.kind) }
        return commentTokens.compactMap { (token: SwiftLintSyntaxToken) -> [NSRange]? in
            guard let commentBody = file.stringView.substringWithByteRange(token.range).map(StringView.init) else {
                return nil
            }
            // Look for 2-3 slash characters followed immediately by a non-whitespace, non-slash
            // character (this is a violation)
            return regex(#"^(\/){2,3}[^\s\/]"#).matches(in: commentBody, options: .anchored)
                .compactMap { result in
                    // Set the location to be directly before the first non-slash,
                    // non-whitespace character which was matched
                    guard let characterRange = file.stringView.byteRangeToNSRange(
                        ByteRange(
                            location: ByteCount(
                                token.range.lowerBound.value + result.range.upperBound - 1
                            ),
                            length: ByteCount(1)
                        )
                    ) else {
                        return nil
                    }
                    return characterRange
                }
        }.flatMap { $0 }
    }

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map { range in
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location)
            )
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        let violationCharacters = file.stringView.substring(with: violationRange)
        // Since the violation range is just the first character after the slashes, all we have to
        // do is prepend a single space
        return (violationRange, " \(violationCharacters)")
    }
}
