import SwiftSyntax

struct TrailingCommaRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = TrailingCommaConfiguration()

    init() {}

    private static let triggeringExamples: [Example] = [
        Example("let foo = [1, 2, 3↓,]\n"),
        Example("let foo = [1, 2, 3↓, ]\n"),
        Example("let foo = [1, 2, 3   ↓,]\n"),
        Example("let foo = [1: 2, 2: 3↓, ]\n"),
        Example("struct Bar {\n let foo = [1: 2, 2: 3↓, ]\n}\n"),
        Example("let foo = [1, 2, 3↓,] + [4, 5, 6↓,]\n"),
        Example("let example = [ 1,\n2↓,\n // 3,\n]"),
        Example("let foo = [\"אבג\", \"αβγ\", \"🇺🇸\"↓,]\n"),
        Example("class C {\n #if true\n func f() {\n let foo = [1, 2, 3↓,]\n }\n #endif\n}"),
        Example("foo([1: \"\\(error)\"↓,])\n")
    ]

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
        nonTriggeringExamples: [
            Example("let foo = [1, 2, 3]\n"),
            Example("let foo = []\n"),
            Example("let foo = [:]\n"),
            Example("let foo = [1: 2, 2: 3]\n"),
            Example("let foo = [Void]()\n"),
            Example("let example = [ 1,\n 2\n // 3,\n]"),
            Example("foo([1: \"\\(error)\"])\n"),
            Example("let foo = [Int]()\n")
        ],
        triggeringExamples: Self.triggeringExamples,
        corrections: Self.corrections
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(
            mandatoryComma: configuration.mandatoryComma,
            locationConverter: file.locationConverter
        )
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            mandatoryComma: configuration.mandatoryComma,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension TrailingCommaRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let mandatoryComma: Bool
        private let locationConverter: SourceLocationConverter

        init(mandatoryComma: Bool, locationConverter: SourceLocationConverter) {
            self.mandatoryComma = mandatoryComma
            self.locationConverter = locationConverter
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: DictionaryElementListSyntax) {
            guard let lastElement = node.last else {
                return
            }

            switch (lastElement.trailingComma, mandatoryComma) {
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

            switch (lastElement.trailingComma, mandatoryComma) {
            case (let commaToken?, false):
                violations.append(violation(for: commaToken.positionAfterSkippingLeadingTrivia))
            case (nil, true) where !locationConverter.isSingleLine(node: node):
                violations.append(violation(for: lastElement.endPositionBeforeTrailingTrivia))
            case (_, true), (nil, false):
                break
            }
        }

        private func violation(for position: AbsolutePosition) -> ReasonedRuleViolation {
            let reason = mandatoryComma
                ? "Multi-line collection literals should have trailing commas"
                : "Collection literals should not have trailing commas"
            return ReasonedRuleViolation(position: position, reason: reason)
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        private let mandatoryComma: Bool
        private let locationConverter: SourceLocationConverter
        private let disabledRegions: [SourceRange]

        init(mandatoryComma: Bool, locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.mandatoryComma = mandatoryComma
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: DictionaryElementListSyntax) -> DictionaryElementListSyntax {
            guard let lastElement = node.last,
                    !lastElement.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            switch (lastElement.trailingComma, mandatoryComma) {
            case (let commaToken?, false):
                correctionPositions.append(commaToken.positionAfterSkippingLeadingTrivia)
                let newNode = node
                    .replacing(
                        childAt: lastElement.indexInParent,
                        with: lastElement
                            .withTrailingComma(nil)
                            .withTrailingTrivia(
                                (lastElement.valueExpression.trailingTrivia ?? .zero)
                                    .appending(trivia: commaToken.leadingTrivia)
                                    .appending(trivia: commaToken.trailingTrivia)
                            )
                    )
                return super.visit(newNode)
            case (nil, true) where !locationConverter.isSingleLine(node: node):
                correctionPositions.append(lastElement.endPositionBeforeTrailingTrivia)
                let newNode = node
                    .replacing(
                        childAt: lastElement.indexInParent,
                        with: lastElement
                            .withoutTrailingTrivia()
                            .withTrailingComma(.commaToken())
                            .withTrailingTrivia(lastElement.trailingTrivia ?? .zero)
                    )
                return super.visit(newNode)
            case (_, true), (nil, false):
                return super.visit(node)
            }
        }

        override func visit(_ node: ArrayElementListSyntax) -> ArrayElementListSyntax {
            guard let lastElement = node.last,
                  !lastElement.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            switch (lastElement.trailingComma, mandatoryComma) {
            case (let commaToken?, false):
                correctionPositions.append(commaToken.positionAfterSkippingLeadingTrivia)
                let newNode = node
                    .replacing(
                        childAt: lastElement.indexInParent,
                        with: lastElement
                            .withTrailingComma(nil)
                            .withTrailingTrivia(
                                (lastElement.expression.trailingTrivia ?? .zero)
                                    .appending(trivia: commaToken.leadingTrivia)
                                    .appending(trivia: commaToken.trailingTrivia)
                            )
                    )
                return super.visit(newNode)
            case (nil, true) where !locationConverter.isSingleLine(node: node):
                correctionPositions.append(lastElement.endPositionBeforeTrailingTrivia)
                let newNode = node.replacing(
                    childAt: lastElement.indexInParent,
                    with: lastElement
                        .withExpression(lastElement.expression.withoutTrailingTrivia())
                        .withTrailingComma(.commaToken())
                        .withTrailingTrivia(lastElement.expression.trailingTrivia ?? .zero)
                )
                return super.visit(newNode)
            case (_, true), (nil, false):
                return super.visit(node)
            }
        }
    }
}

private extension SourceLocationConverter {
    func isSingleLine(node: SyntaxProtocol) -> Bool {
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
