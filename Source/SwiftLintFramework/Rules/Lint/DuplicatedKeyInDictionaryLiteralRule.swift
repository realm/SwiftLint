import SwiftSyntax

public struct DuplicatedKeyInDictionaryLiteralRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "duplicated_key_in_dictionary_literal",
        name: "Duplicated Key in Dictionary Literal",
        description: "Dictionary literals with duplicated keys will crash in runtime.",
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DuplicatedKeyInDictionaryLiteralRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: DictionaryExprSyntax) {
            guard let content = node.content.as(DictionaryElementListSyntax.self) else {
                return
            }

            var seenKeys: Set<String> = []
            for keyValue in content {
                let key = keyValue.keyExpression.withoutTrivia().description
                if isCodeGeneratedKey(keyExpression: key) {
                    continue
                } else if seenKeys.contains(key) {
                    violations.append(keyValue.keyExpression.positionAfterSkippingLeadingTrivia)
                } else {
                    seenKeys.insert(key)
                }
            }
        }
    }
}

private func isCodeGeneratedKey(keyExpression: String) -> Bool {
    if keyExpression == "#line" {
        return true
    }

    guard let openingParenthesisIndex = keyExpression.firstIndex(of: "("),
          let closingParenthesisIndex = keyExpression.lastIndex(of: Character(")")) else {
        return false
    }

    return openingParenthesisIndex < closingParenthesisIndex
}
