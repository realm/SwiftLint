import Foundation
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct TrailingCommaRule: Rule {
    var configuration = TrailingCommaConfiguration()

    private static let triggeringExamples: [Example] = #examples([
        "let foo = [1, 2, 3↓,]",
        "let foo = [1, 2, 3↓, ]",
        "let foo = [1, 2, 3   ↓,]",
        "let foo = [1: 2, 2: 3↓, ]",
        "struct Bar {\n let foo = [1: 2, 2: 3↓, ]\n}",
        "let foo = [1, 2, 3↓,] + [4, 5, 6↓,]",
        "let example = [ 1,\n2↓,\n // 3,\n]",
        "let foo = [\"אבג\", \"αβγ\", \"🇺🇸\"↓,]",
        "class C {\n #if true\n func f() {\n let foo = [1, 2, 3↓,]\n }\n #endif\n}",
        "foo([1: \"\\(error)\"↓,])",
    ])

    private static let corrections: [Example: Example] = {
        let fixed = triggeringExamples.map { example -> Example in
            let fixedString = example.code.replacingOccurrences(of: "↓,", with: "")
            return example.with(code: fixedString)
        }
        var result: [Example: Example] = [:]
        for (triggering, correction) in zip(triggeringExamples, fixed) {
            result[triggering] = correction
        }
        return result
    }()

    static let description = RuleDescription(
        identifier: "trailing_comma",
        name: "Trailing Comma",
        description: "Trailing commas in arrays and dictionaries should be avoided/enforced.",
        kind: .style,
        nonTriggeringExamples: #examples([
            "let foo = [1, 2, 3]",
            "let foo = []",
            "let foo = [:]",
            "let foo = [1: 2, 2: 3]",
            "let foo = [Void]()",
            "let example = [ 1,\n 2\n // 3,\n]",
            "foo([1: \"\\(error)\"])",
            "let foo = [Int]()",
        ]),
        triggeringExamples: Self.triggeringExamples,
        corrections: Self.corrections
    )
}

private extension TrailingCommaRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DictionaryElementListSyntax) {
            guard let lastElement = node.last else {
                return
            }

            switch (lastElement.trailingComma, configuration.mandatoryComma) {
            case (let commaToken?, false):
                violations.append(violation(for: commaToken.positionAfterSkippingLeadingTrivia))
            case (nil, true) where !locationConverter.isSingleLine(node: node):
                violations.append(violation(for: lastElement.endPositionBeforeTrailingTrivia))
            case (_, true), (nil, false):
                break
            }
        }

        override func visitPost(_ node: ArrayElementListSyntax) {
            guard let lastElement = node.last else {
                return
            }

            switch (lastElement.trailingComma, configuration.mandatoryComma) {
            case (let commaToken?, false):
                violations.append(violation(for: commaToken.positionAfterSkippingLeadingTrivia))
            case (nil, true) where !locationConverter.isSingleLine(node: node):
                violations.append(violation(for: lastElement.endPositionBeforeTrailingTrivia))
            case (_, true), (nil, false):
                break
            }
        }

        private func violation(for position: AbsolutePosition) -> ReasonedRuleViolation {
            let reason = configuration.mandatoryComma
                ? "Multi-line collection literals should have trailing commas"
                : "Collection literals should not have trailing commas"
            return ReasonedRuleViolation(position: position, reason: reason)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: DictionaryElementListSyntax) -> DictionaryElementListSyntax {
            guard let lastElement = node.last, let index = node.index(of: lastElement) else {
                return super.visit(node)
            }

            switch (lastElement.trailingComma, configuration.mandatoryComma) {
            case (let commaToken?, false):
                numberOfCorrections += 1
                let newTrailingTrivia = (lastElement.value.trailingTrivia)
                    .appending(trivia: commaToken.leadingTrivia)
                    .appending(trivia: commaToken.trailingTrivia)
                let newNode = node
                    .with(
                        \.[index],
                        lastElement
                            .with(\.trailingComma, nil)
                            .with(\.trailingTrivia, newTrailingTrivia)
                    )
                return super.visit(newNode)
            case (nil, true) where !locationConverter.isSingleLine(node: node):
                numberOfCorrections += 1
                let newNode = node
                    .with(
                        \.[index],
                        lastElement
                            .with(\.trailingTrivia, [])
                            .with(\.trailingComma, .commaToken())
                            .with(\.trailingTrivia, lastElement.trailingTrivia)
                    )
                return super.visit(newNode)
            case (_, true), (nil, false):
                return super.visit(node)
            }
        }

        override func visit(_ node: ArrayElementListSyntax) -> ArrayElementListSyntax {
            guard let lastElement = node.last, let index = node.index(of: lastElement) else {
                return super.visit(node)
            }

            switch (lastElement.trailingComma, configuration.mandatoryComma) {
            case (let commaToken?, false):
                numberOfCorrections += 1
                let newNode = node
                    .with(
                        \.[index],
                        lastElement
                            .with(\.trailingComma, nil)
                            .with(\.trailingTrivia,
                                  (lastElement.expression.trailingTrivia)
                                        .appending(trivia: commaToken.leadingTrivia)
                                        .appending(trivia: commaToken.trailingTrivia)
                            )
                    )
                return super.visit(newNode)
            case (nil, true) where !locationConverter.isSingleLine(node: node):
                numberOfCorrections += 1
                let newNode = node
                    .with(
                        \.[index],
                        lastElement
                            .with(\.expression, lastElement.expression.with(\.trailingTrivia, []))
                            .with(\.trailingComma, .commaToken())
                            .with(\.trailingTrivia, lastElement.expression.trailingTrivia)
                    )
                return super.visit(newNode)
            case (_, true), (nil, false):
                return super.visit(node)
            }
        }
    }
}

private extension SourceLocationConverter {
    func isSingleLine(node: some SyntaxProtocol) -> Bool {
        location(for: node.positionAfterSkippingLeadingTrivia).line ==
            location(for: node.endPositionBeforeTrailingTrivia).line
    }
}

private extension Trivia {
    func appending(trivia: Trivia) -> Trivia {
        var result = self
        for piece in trivia.pieces {
            result = result.appending(piece)
        }
        return result
    }
}
