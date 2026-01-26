import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct InvisibleCharacterRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    // swiftlint:disable invisible_character
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
        ]
    )
    // swiftlint:enable invisible_character

    private static let invisibleCharacters: [Unicode.Scalar: String] = [
        "\u{200B}": "U+200B (zero-width space)",
        "\u{200C}": "U+200C (zero-width non-joiner)",
        "\u{FEFF}": "U+FEFF (zero-width no-break space)",
    ]

    private static let invisibleCharacterSet: Set<Unicode.Scalar> = Set(invisibleCharacters.keys)
}

private extension InvisibleCharacterRule {
    static func violatingSegments(
        in node: StringLiteralExprSyntax
    ) -> [SyntaxIdentifier: (segment: StringSegmentSyntax, text: String)] {
        var result = [SyntaxIdentifier: (StringSegmentSyntax, String)]()
        for segment in node.segments {
            guard let stringSegment = segment.as(StringSegmentSyntax.self) else {
                continue
            }
            let text = stringSegment.content.text
            if text.unicodeScalars.contains(where: { invisibleCharacterSet.contains($0) }) {
                result[stringSegment.id] = (stringSegment, text)
            }
        }
        return result
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: StringLiteralExprSyntax) {
            for (segment, text) in violatingSegments(in: node).values {
                var utf8Offset = 0
                for scalar in text.unicodeScalars {
                    defer { utf8Offset += scalar.utf8Length }
                    guard let characterName = invisibleCharacters[scalar] else {
                        continue
                    }
                    violations.append(
                        ReasonedRuleViolation(
                            position: segment.content.positionAfterSkippingLeadingTrivia
                                .advanced(by: utf8Offset),
                            reason: "String literal should not contain invisible character \(characterName)"
                        )
                    )
                }
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
            guard !isDisabled(atStartPositionOf: node) else {
                return super.visit(node)
            }

            let segmentsToFix = violatingSegments(in: node)
            guard segmentsToFix.isNotEmpty else {
                return super.visit(node)
            }

            var correctionCount = 0

            let newSegments = node.segments.map { segment -> StringLiteralSegmentListSyntax.Element in
                guard let stringSegment = segment.as(StringSegmentSyntax.self),
                      let (_, text) = segmentsToFix[stringSegment.id] else {
                    return segment
                }

                var cleanedScalars = [Unicode.Scalar]()
                cleanedScalars.reserveCapacity(text.unicodeScalars.count)
                var removedCount = 0

                for scalar in text.unicodeScalars {
                    if invisibleCharacterSet.contains(scalar) {
                        removedCount += 1
                    } else {
                        cleanedScalars.append(scalar)
                    }
                }

                correctionCount += removedCount
                let cleanedText = String(String.UnicodeScalarView(cleanedScalars))
                let newSegment = stringSegment.with(
                    \.content,
                    stringSegment.content.with(\.tokenKind, .stringSegment(cleanedText))
                )
                return .stringSegment(newSegment)
            }

            numberOfCorrections += correctionCount
            let newNode = node.with(\.segments, StringLiteralSegmentListSyntax(newSegments))
            return super.visit(newNode)
        }
    }
}
