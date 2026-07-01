import Foundation
import SourceKittenFramework
import SwiftIDEUtils
import SwiftLintCore

struct PeriodSpacingRule: SourceKitFreeRule, OptInRule, SubstitutionCorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "period_spacing",
        name: "Period Spacing",
        description: "Periods should not be followed by more than one space",
        kind: .style,
        nonTriggeringExamples: #examples([
            "let pi = 3.2",
            "let pi = Double.pi",
            "let pi = Double. pi",
            "let pi = Double.  pi",
            "// A. Single.",
            "///   - code: Identifier of the error. Integer.",
            """
            // value: Multiline.
            //        Comment.
            """,
            """
            /**
            Sentence ended in period.

            - Sentence 2 new line characters after.
            **/
            """,
        ]),
        triggeringExamples: #examples([
            "/* Only god knows why. ↓ This symbol does nothing. */".skipWrappingInCommentTest(),
            "// Only god knows why. ↓ This symbol does nothing.".skipWrappingInCommentTest(),
            "// Single. Double. ↓ End.".skipWrappingInCommentTest(),
            "// Single. Double. ↓ Triple. ↓  End.".skipWrappingInCommentTest(),
            "// Triple. ↓  Quad. ↓   End.".skipWrappingInCommentTest(),
            "///   - code: Identifier of the error. ↓ Integer.".skipWrappingInCommentTest(),
        ]),
        corrections: #corrections([
            "/* Why. ↓ Symbol does nothing. */": "/* Why. Symbol does nothing. */",
            "// Why. ↓ Symbol does nothing.": "// Why. Symbol does nothing.",
            "// Single. Double. ↓ End.": "// Single. Double. End.",
            "// Single. Double. ↓ Triple. ↓  End.": "// Single. Double. Triple. End.",
            "// Triple. ↓  Quad. ↓   End.": "// Triple. Quad. End.",
            "///   - code: Identifier. ↓ Integer.": "///   - code: Identifier. Integer.",
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
                        // Look for a period followed by two or more whitespaces but not new line or carriage returns
                        regex(#"\.[^\S\r\n]{2,}"#)
                            .matches(in: commentBody)
                            .compactMap { result in
                                // Set the location to start from the second whitespace till the last one.
                                file.stringView.byteRangeToNSRange(
                                    ByteRange(
                                        // Safe to mix NSRange offsets with byte offsets here because the
                                        // regex can't contain multi-byte characters
                                        location: ByteCount(range.lowerBound.value + result.range.lowerBound + 2),
                                        length: ByteCount(result.range.length.advanced(by: -2))
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
        (violationRange, "")
    }
}
