import SwiftSyntax

@SwiftSyntaxRule(correctable: true)
struct InvisibleCharacterRule: Rule {
    var configuration = InvisibleCharacterConfiguration()

    // swiftlint:disable invisible_character
    static let description = RuleDescription(
        identifier: "invisible_character",
        name: "Invisible Character",
        description: """
            Disallows invisible characters like zero-width space (U+200B), \
            zero-width non-joiner (U+200C), and FEFF formatting character (U+FEFF) \
            in string literals as they can cause hard-to-debug issues.
            """,
        kind: .lint,
        nonTriggeringExamples: [
            Example(#"let s = "HelloWorld""#),
            Example(#"let s = "Hello World""#),
            Example(#"let url = "https://example.com/api""#),
            Example(##"let s = #"Hello World"#"##),
            Example("""
            let multiline = \"\"\"
            Hello
            World
            \"\"\"
            """),
            Example(#"let empty = """#),
            Example(#"let tab = "Hello\tWorld""#),
            Example(#"let newline = "Hello\nWorld""#),
            Example(#"let unicode = "Hello 👋 World""#),
        ],
        triggeringExamples: [
            Example(#"let s = "Hello↓​World" // U+200B zero-width space"#),
            Example(#"let s = "Hello↓‌World" // U+200C zero-width non-joiner"#),
            Example(#"let s = "Hello↓﻿World" // U+FEFF formatting character"#),
            Example(#"let url = "https://example↓​.com" // U+200B in URL"#),
            Example("""
            // U+200B in multiline string
            let multiline = \"\"\"
            Hello↓​World
            \"\"\"
            """),
            Example(#"let s = "Test↓​String↓﻿Here" // Multiple invisible characters"#),
            Example(#"let s = "Hel↓‌lo" + "World" // string concatenation with U+200C"#),
            Example(#"let s = "Hel↓‌lo \(name)" // U+200C in interpolated string"#),
            Example("""
            //
            // additional_code_points: ["00AD"]
            //
            let s = "Hello↓­World"
            """,
            configuration: [
                "additional_code_points": ["00AD"],
            ]
            ),
            Example("""
            //
            // additional_code_points: ["200D"]
            //
            let s = "Hello↓‍World"
            """,
            configuration: [
                "additional_code_points": ["200D"],
            ]
            ),
        ],
        corrections: [
            Example(#"let s = "Hello​World""#): Example(#"let s = "HelloWorld""#),
            Example(#"let s = "Hello‌World""#): Example(#"let s = "HelloWorld""#),
            Example(#"let s = "Hello﻿World""#): Example(#"let s = "HelloWorld""#),
            Example(#"let url = "https://example​.com""#): Example(#"let url = "https://example.com""#),
            Example("""
            let multiline = \"\"\"
            Hello​World
            \"\"\"
            """): Example("""
            let multiline = \"\"\"
            HelloWorld
            \"\"\"
            """),
            Example(#"let s = "Test​String﻿Here""#): Example(#"let s = "TestStringHere""#),
            Example(#"let s = "Hel‌lo" + "World""#): Example(#"let s = "Hello" + "World""#),
            Example(#"let s = "Hel‌lo \(name)""#): Example(#"let s = "Hello \(name)""#),
            Example(
                #"let s = "Hello­World""#,
                configuration: [
                    "additional_code_points": ["00AD"],
                ]
            ): Example(
                #"let s = "HelloWorld""#,
                configuration: [
                    "additional_code_points": ["00AD"],
                ]
            ),
            Example(
                #"let s = "Hello‍World""#,
                configuration: [
                    "additional_code_points": ["200D"],
                ]
            ): Example(
                #"let s = "HelloWorld""#,
                configuration: [
                    "additional_code_points": ["200D"],
                ]
            ),
        ]
    )
    // swiftlint:enable invisible_character
}

private extension InvisibleCharacterRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: StringLiteralExprSyntax) {
            let violatingCharacters = configuration.violatingCharacters
            for segment in node.segments {
                guard let stringSegment = segment.as(StringSegmentSyntax.self) else {
                    continue
                }
                let text = stringSegment.content.text
                let scalars = text.unicodeScalars
                guard scalars.contains(where: { violatingCharacters.contains($0) }) else {
                    continue
                }
                var utf8Offset = 0
                var previousScalar: UnicodeScalar?
                var previousUtf8Size = 0

                for scalar in scalars {
                    defer {
                        previousScalar = scalar
                        previousUtf8Size = scalar.utf8.count
                        utf8Offset += scalar.utf8.count
                    }
                    guard violatingCharacters.contains(scalar) else {
                        continue
                    }

                    let characterName = InvisibleCharacterConfiguration.defaultCharacterDescriptions[scalar.value]
                        ?? scalar.escaped(asASCII: true)

                    // Check if this scalar forms a grapheme cluster with the previous one.
                    // This is needed on Windows and Linux where NSString operations on grapheme clusters
                    // can delete more than intended when removing a combining character like ZWJ.
                    let formsCombinedCluster: Bool
                    if let prev = previousScalar {
                        let combined = String(prev) + String(scalar)
                        formsCombinedCluster = combined.count == 1
                    } else {
                        formsCombinedCluster = false
                    }

                    let correctionStart: AbsolutePosition
                    let replacement: String

                    if formsCombinedCluster, let prev = previousScalar {
                        // Include previous scalar in the correction range and use it as replacement
                        correctionStart = stringSegment.content.positionAfterSkippingLeadingTrivia
                            .advanced(by: utf8Offset - previousUtf8Size)
                        replacement = String(prev)
                    } else {
                        correctionStart = stringSegment.content.positionAfterSkippingLeadingTrivia
                            .advanced(by: utf8Offset)
                        replacement = ""
                    }

                    let position = stringSegment.content.positionAfterSkippingLeadingTrivia.advanced(by: utf8Offset)
                    violations.append(
                        ReasonedRuleViolation(
                            position: position,
                            reason: "String literal should not contain invisible character \(characterName)",
                            correction: .init(
                                start: correctionStart,
                                end: position.advanced(by: scalar.utf8.count),
                                replacement: replacement
                            )
                        )
                    )
                }
            }
        }
    }
}
