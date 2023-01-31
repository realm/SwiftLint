import SwiftSyntax

struct DuplicatedKeyInDictionaryLiteralRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static var description = RuleDescription(
        identifier: "duplicated_key_in_dictionary_literal",
        name: "Duplicated Key in Dictionary Literal",
        description: "Dictionary literals with duplicated keys will crash at runtime",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                [
                    1: "1",
                    2: "2"
                ]
            """),
            Example("""
                [
                    "1": 1,
                    "2": 2
                ]
            """),
            Example("""
                [
                    foo: "1",
                    bar: "2"
                ]
            """),
            Example("""
                [
                    UUID(): "1",
                    UUID(): "2"
                ]
            """),
            Example("""
                [
                    #line: "1",
                    #line: "2"
                ]
            """)
        ],
        triggeringExamples: [
            Example("""
                [
                    1: "1",
                    2: "2",
                    ↓1: "one"
                ]
            """),
            Example("""
                [
                    "1": 1,
                    "2": 2,
                    ↓"2": 2
                ]
            """),
            Example("""
                [
                    foo: "1",
                    bar: "2",
                    baz: "3",
                    ↓foo: "4",
                    zaz: "5"
                ]
            """),
            Example("""
                [
                    .one: "1",
                    .two: "2",
                    .three: "3",
                    ↓.one: "1",
                    .four: "4",
                    .five: "5"
                ]
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DuplicatedKeyInDictionaryLiteralRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ list: DictionaryElementListSyntax) {
            let keys = list.map(\.keyExpression).compactMap { expr -> DictionaryKey? in
                expr.stringContent.map {
                    DictionaryKey(position: expr.positionAfterSkippingLeadingTrivia, content: $0)
                }
            }

            guard keys.count >= 2 else {
                return
            }

            let newViolations = keys
                .reduce(into: [String: [DictionaryKey]]()) { result, key in
                    result[key.content, default: []].append(key)
                }
                .flatMap { _, value -> [AbsolutePosition] in
                    guard value.count > 1 else {
                        return []
                    }

                    return value.dropFirst().map(\.position)
                }

            violations.append(contentsOf: newViolations)
        }
    }
}

private struct DictionaryKey {
    let position: AbsolutePosition
    let content: String
}

private extension ExprSyntax {
    var stringContent: String? {
        if let string = self.as(StringLiteralExprSyntax.self) {
            return string.description
        } else if let int = self.as(IntegerLiteralExprSyntax.self) {
            return int.description
        } else if let float = self.as(FloatLiteralExprSyntax.self) {
            return float.description
        } else if let memberAccess = self.as(MemberAccessExprSyntax.self) {
            return memberAccess.description
        } else if let identifier = self.as(IdentifierExprSyntax.self) {
            return identifier.identifier.text
        }

        return nil
    }
}
