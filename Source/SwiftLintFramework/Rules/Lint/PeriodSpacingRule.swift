import Foundation
import IDEUtils
import SourceKittenFramework

struct PeriodSpacingRule: SourceKitFreeRule, ConfigurationProviderRule, OptInRule, SubstitutionCorrectableRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "period_spacing",
        name: "Period Spacing",
        description: "Periods should not be followed by more than one space",
        kind: .style,
        nonTriggeringExamples: [
            Example("let pi = 3.2"),
            Example("let pi = Double.pi"),
            Example("let pi = Double. pi"),
            Example("let pi = Double.  pi"),
            Example("// A. Single."),
            Example("///   - code: Identifier of the error. Integer."),
            Example("""
            // value: Multiline.
            //        Comment.
            """),
            Example("""
            /**
            Sentence ended in period.

            - Sentence 2 new line characters after.
            **/
            """)
        ],
        triggeringExamples: [
            Example("/* Only god knows why. ↓ This symbol does nothing. */", testWrappingInComment: false),
            Example("// Only god knows why. ↓ This symbol does nothing.", testWrappingInComment: false),
            Example("// Single. Double. ↓ End.", testWrappingInComment: false),
            Example("// Single. Double. ↓ Triple. ↓  End.", testWrappingInComment: false),
            Example("// Triple. ↓  Quad. ↓   End.", testWrappingInComment: false),
            Example("///   - code: Identifier of the error. ↓ Integer.", testWrappingInComment: false)
        ],
        corrections: [
            Example("/* Why. ↓ Symbol does nothing. */"): Example("/* Why. Symbol does nothing. */"),
            Example("// Why. ↓ Symbol does nothing."): Example("// Why. Symbol does nothing."),
            Example("// Single. Double. ↓ End."): Example("// Single. Double. End."),
            Example("// Single. Double. ↓ Triple. ↓  End."): Example("// Single. Double. Triple. End."),
            Example("// Triple. ↓  Quad. ↓   End."): Example("// Triple. Quad. End."),
            Example("///   - code: Identifier. ↓ Integer."): Example("///   - code: Identifier. Integer.")
        ]
    )

    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        // Find all comment tokens in the file and regex search them for violations
        file.syntaxClassifications
            .filter(\.kind.isComment)
            .map { $0.range.toSourceKittenByteRange() }
            .compactMap { (range: ByteRange) -> [NSRange]? in
                return file.stringView
                    .substringWithByteRange(range)
                    .map(StringView.init)
                    .map { commentBody in
                        // Look for a period followed by two or more whitespaces but not new line or carriage returns
                        return regex(#"\.[^\S\r\n]{2,}"#)
                            .matches(in: commentBody)
                            .compactMap { result in
                                // Set the location to start from the second whitespace till the last one.
                                return file.stringView.byteRangeToNSRange(
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
            .flatMap { $0 }
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map { range in
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location)
            )
        }
    }

    func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }
}
