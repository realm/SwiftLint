import SwiftSyntax

@SwiftSyntaxRule
struct DuplicatedKeyInDictionaryLiteralRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
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
                """),
            Example("""
                var currentValue = 0
                var generateNewValue: Int {
                    let current = currentValue
                    currentValue += 1
                    return current
                }

                let testDict = [
                    generateNewValue: "",
                    generateNewValue: "",
                    generateNewValue: "",
                ]
                """),
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
                """),
        ]
    )
}

private extension DuplicatedKeyInDictionaryLiteralRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var computedPropertyNames = Set<String>()

        override func visitPost(_ node: VariableDeclSyntax) {
            for binding in node.bindings {
                guard binding.accessorBlock != nil,
                      let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }

                computedPropertyNames.insert(pattern.identifier.text)
            }
        }

        override func visitPost(_ list: DictionaryElementListSyntax) {
            let keys = list.map(\.key).compactMap { expr -> DictionaryKey? in
                if let identifier = expr.as(DeclReferenceExprSyntax.self),
                   computedPropertyNames.contains(identifier.baseName.text) {
                    return nil
                }

                return expr.stringContent.map {
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
        if let string = `as`(StringLiteralExprSyntax.self) {
            return string.description
        }
        if let int = `as`(IntegerLiteralExprSyntax.self) {
            return int.description
        }
        if let float = `as`(FloatLiteralExprSyntax.self) {
            return float.description
        }
        if let memberAccess = `as`(MemberAccessExprSyntax.self) {
            return memberAccess.description
        }
        if let identifier = `as`(DeclReferenceExprSyntax.self) {
            return identifier.baseName.text
        }

        return nil
    }
}
