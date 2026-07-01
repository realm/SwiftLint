import Foundation
import SourceKittenFramework
import SwiftIDEUtils

struct CommentSpacingRule: SourceKitFreeRule, SubstitutionCorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "comment_spacing",
        name: "Comment Spacing",
        description: "Prefer at least one space after slashes for comments",
        kind: .lint,
        nonTriggeringExamples: #examples([
            """
            // This is a comment
            """,
            """
            /// Triple slash comment
            """,
            """
            // Multiline double-slash
            // comment
            """,
            """
            /// Multiline triple-slash
            /// comment
            """,
            """
            /// Multiline triple-slash
            ///   - This is indented
            """,
            """
            // - MARK: Mark comment
            """,
            """
            //: Swift Playground prose section
            """,
            """
            ///////////////////////////////////////////////
            // Comment with some lines of slashes boxing it
            ///////////////////////////////////////////////
            """,
            """
            //:#localized(key: "SwiftPlaygroundLocalizedProse")
            """,
            """
            /* Asterisk comment */
            """,
            """
            /*
                Multiline asterisk comment
            */
            """,
            """
            /*:
                Multiline Swift Playground prose section
            */
            """,
            """
            /*#-editable-code Swift Playground editable area*/default/*#-end-editable-code*/
            """,
        ]),
        triggeringExamples: #examples([
            """
            //↓Something
            """,
            """
            //↓MARK
            """,
            """
            //↓👨‍👨‍👦‍👦Something
            """,
            """
            func a() {
                //↓This needs refactoring
                print("Something")
            }
            //↓We should improve above function
            """,
            """
            ///↓This is a comment
            """,
            """
            /// Multiline triple-slash
            ///↓This line is incorrect, though
            """,
            """
            //↓- MARK: Mark comment
            """,
            """
            //:↓Swift Playground prose section
            """,
        ]),
        corrections: #corrections([
            "//↓Something": "// Something",
            "//↓- MARK: Mark comment": "// - MARK: Mark comment",
            """
            /// Multiline triple-slash
            ///↓This line is incorrect, though
            """: """
            /// Multiline triple-slash
            /// This line is incorrect, though
            """,
            """
            func a() {
                //↓This needs refactoring
                print("Something")
            }
            //↓We should improve above function
            """: """
            func a() {
                // This needs refactoring
                print("Something")
            }
            // We should improve above function
            """,
        ])
    )

    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        // Find all comment tokens in the file and regex search them for violations
        file.syntaxClassifications
            .filter(\.kind.isComment)
            .map { $0.range.toSourceKittenByteRange() }
            .compactMap { (range: ByteRange) -> [NSRange]? in
                file.stringView
                    .substringWithByteRange(range)
                    .map(StringView.init)
                    .map { commentBody in
                        // Look for 2+ slash characters followed immediately by
                        // a non-colon, non-whitespace character or by a colon
                        // followed by a non-whitespace character other than #
                        regex(#"^(?:\/){2,}+(?:[^\s:]|:[^\s#])"#).matches(in: commentBody, options: .anchored)
                            .compactMap { result in
                                // Set the location to be directly before the first non-slash,
                                // non-whitespace character which was matched
                                file.stringView.byteRangeToNSRange(
                                    ByteRange(
                                        // Safe to mix NSRange offsets with byte offsets here because the regex can't
                                        // contain multi-byte characters
                                        location: ByteCount(range.lowerBound.value + result.range.upperBound - 1),
                                        length: 0
                                    )
                                )
                            }
                    }
            }
            .flatMap(\.self)
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        violationRanges(in: file).map { range in
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location)
            )
        }
    }

    func substitution(for violationRange: NSRange, in _: SwiftLintFile) -> (NSRange, String)? {
        (violationRange, " ")
    }
}
