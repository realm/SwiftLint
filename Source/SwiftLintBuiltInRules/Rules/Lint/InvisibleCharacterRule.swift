import SwiftSyntax

@SwiftSyntaxRule
struct InvisibleCharacterRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "invisible_character",
        name: "Invisible Character",
        description: """
            Disallows invisible characters like zero-width space (U+200B), \
            zero-width non-joiner (U+200C), and FEFF formatting character (U+FEFF) \
            in string literals as they can cause hard-to-debug issues
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
            // swiftlint:disable invisible_character
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
            // swiftlint:enable invisible_character
        ]
    )

    private static let invisibleCharacters: [Unicode.Scalar: String] = [
        "\u{200B}": "U+200B (zero-width space)",
        "\u{200C}": "U+200C (zero-width non-joiner)",
        "\u{FEFF}": "U+FEFF (zero-width no-break space)",
    ]
}

private extension InvisibleCharacterRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: StringLiteralExprSyntax) {
            let invisibleCharactersKeys = InvisibleCharacterRule.invisibleCharacters.keys

            for segment in node.segments {
                guard let stringSegment = segment.as(StringSegmentSyntax.self) else {
                    continue
                }

                let text = stringSegment.content.text

                // Early exit if no invisible characters present
                guard text.unicodeScalars.contains(where: {
                    invisibleCharactersKeys.contains($0)
                }) else {
                    continue
                }

                // Find all invisible characters and their positions
                var utf8Offset = 0
                for scalar in text.unicodeScalars {
                    if let character = InvisibleCharacterRule.invisibleCharacters[scalar] {
                        violations.append(
                            ReasonedRuleViolation(
                                position: stringSegment.content.positionAfterSkippingLeadingTrivia
                                    .advanced(by: utf8Offset),
                                reason: "String literal should not contain invisible character \(character)"
                            )
                        )
                    }
                    utf8Offset += String(scalar).utf8.count
                }
            }
        }
    }
}
