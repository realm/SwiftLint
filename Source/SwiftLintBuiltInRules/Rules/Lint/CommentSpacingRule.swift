import Foundation
import SourceKittenFramework
import SwiftLintCore

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
        let commentRanges = file.commentByteRanges()
        if commentRanges.isEmpty {
            return []
        }
        // Hoisted out of the loop: every `stringView` access synchronizes on a queue in SourceKitten.
        let stringView = file.stringView
        var violations = [NSRange]()
        for range in commentRanges {
            guard let commentNSRange = stringView.byteRangeToNSRange(range),
                  Self.mayViolate(commentAt: commentNSRange, in: stringView.nsString) else {
                continue
            }
            // Look for 2+ slash characters followed immediately by
            // a non-colon, non-whitespace character or by a colon
            // followed by a non-whitespace character other than #
            let matches = Self.violationRegex.matches(in: stringView, options: .anchored, range: commentNSRange)
            for result in matches {
                // Set the location to be directly before the first non-slash,
                // non-whitespace character which was matched
                let utf16OffsetInComment = result.range.upperBound - commentNSRange.location
                let violationRange = stringView.byteRangeToNSRange(
                    ByteRange(
                        // Safe to mix NSRange offsets with byte offsets here because the regex can't
                        // contain multi-byte characters
                        location: ByteCount(range.lowerBound.value + utf16OffsetInComment - 1),
                        length: 0
                    )
                )
                if let violationRange {
                    violations.append(violationRange)
                }
            }
        }
        return violations
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

    // Matches 2+ slash characters followed immediately by a non-colon, non-whitespace character
    // or by a colon followed by a non-whitespace character other than #.
    private static let violationRegex = regex(#"^(?:\/){2,}+(?:[^\s:]|:[^\s#])"#)

    // Cheaply decides from a comment's first UTF-16 units whether `violationRegex` could possibly
    // match it, so that the regex only runs on candidate comments. Returns `false` only when a
    // match is provably impossible: block comments, all-slash lines, and slashes followed by
    // ASCII whitespace (or by a colon and then ASCII whitespace or `#`). Non-ASCII characters
    // conservatively return `true`, deferring Unicode whitespace semantics to the regex.
    //
    // Takes an `NSString` because `character(at:)` reads raw UTF-16 units by integer offset in
    // O(1), which `String` cannot do.
    // swiftlint:disable:next legacy_objc_type
    private static func mayViolate(commentAt nsRange: NSRange, in nsString: NSString) -> Bool {
        let slash: unichar = 0x2F // "/"
        // A match needs at least two slashes and one more character.
        guard nsRange.length >= 3,
              nsString.character(at: nsRange.location) == slash,
              nsString.character(at: nsRange.location + 1) == slash else {
            return false
        }
        let end = NSMaxRange(nsRange)
        var index = nsRange.location + 2
        while index < end, nsString.character(at: index) == slash {
            index += 1
        }
        guard index < end else {
            return false // A comment consisting solely of slashes, like a box drawn around text.
        }
        var unit = nsString.character(at: index)
        if unit == 0x3A { // ":"
            index += 1
            guard index < end else {
                return false
            }
            unit = nsString.character(at: index)
            if unit == 0x23 { // "#"
                return false
            }
        }
        return !isASCIIWhitespace(unit)
    }

    /// Whether the given UTF-16 unit is an ASCII whitespace character. All of these are matched by
    /// the regex character class `\s`.
    private static func isASCIIWhitespace(_ unit: unichar) -> Bool {
        unit == 0x20 || (0x09...0x0D).contains(unit)
    }
}
