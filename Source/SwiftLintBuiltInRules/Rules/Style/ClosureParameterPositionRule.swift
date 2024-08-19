import SwiftSyntax

@SwiftSyntaxRule
struct ClosureParameterPositionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "closure_parameter_position",
        name: "Closure Parameter Position",
        description: "Closure parameters should be on the same line as opening brace",
        kind: .style,
        nonTriggeringExamples: [
            Example("[1, 2].map { $0 + 1 }"),
            Example("[1, 2].map({ $0 + 1 })"),
            Example("[1, 2].map { number in\n number + 1 \n}"),
            Example("[1, 2].map { number -> Int in\n number + 1 \n}"),
            Example("[1, 2].map { (number: Int) -> Int in\n number + 1 \n}"),
            Example("[1, 2].map { [weak self] number in\n number + 1 \n}"),
            Example("[1, 2].something(closure: { number in\n number + 1 \n})"),
            Example("let isEmpty = [1, 2].isEmpty()"),
            Example("""
            rlmConfiguration.migrationBlock.map { rlmMigration in
                return { migration, schemaVersion in
                    rlmMigration(migration.rlmMigration, schemaVersion)
                }
            }
            """),
            Example("""
            let mediaView: UIView = { [weak self] index in
               return UIView()
            }(index)
            """),
        ],
        triggeringExamples: [
            Example("""
            [1, 2].map {
                ↓number in
                number + 1
            }
            """),
            Example("""
            [1, 2].map {
                ↓number -> Int in
                number + 1
            }
            """),
            Example("""
            [1, 2].map {
                (↓number: Int) -> Int in
                number + 1
            }
            """),
            Example("""
            [1, 2].map {
                [weak ↓self] ↓number in
                number + 1
            }
            """),
            Example("""
            [1, 2].map { [weak self]
                ↓number in
                number + 1
            }
            """),
            Example("""
            [1, 2].map({
                ↓number in
                number + 1
            })
            """),
            Example("""
            [1, 2].something(closure: {
                ↓number in
                number + 1
            })
            """),
            Example("""
            [1, 2].reduce(0) {
                ↓sum, ↓number in
                number + sum
            })
            """),
            Example("""
            f.completionHandler = {
                ↓thing in
                doStuff()
            }
            """),
            Example("""
            foo {
                [weak ↓self] in
                self?.bar()
            }
            """),
        ]
    )
}

private extension ClosureParameterPositionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ClosureExprSyntax) {
            guard let signature = node.signature else {
                return
            }

            let leftBracePosition = node.leftBrace.positionAfterSkippingLeadingTrivia
            let startLine = locationConverter.location(for: leftBracePosition).line

            let positionsToCheck = signature.positionsToCheck
            guard let lastPosition = positionsToCheck.last else {
                return
            }

            // fast path: we can check the last position only, and if that
            // doesn't have a violation, we don't need to check any other positions,
            // since calling `locationConverter.location(for:)` is expensive
            let lastPositionLine = locationConverter.location(for: lastPosition).line
            if lastPositionLine == startLine {
                return
            }
            let localViolations = positionsToCheck.dropLast().filter { position in
                locationConverter.location(for: position).line != startLine
            }

            violations.append(contentsOf: localViolations)
            violations.append(lastPosition)
        }
    }
}

private extension ClosureSignatureSyntax {
    var positionsToCheck: [AbsolutePosition] {
        var positions: [AbsolutePosition] = []
        if let captureItems = capture?.items {
            positions.append(contentsOf: captureItems.map(\.expression.positionAfterSkippingLeadingTrivia))
        }

        if let input = parameterClause?.as(ClosureShorthandParameterListSyntax.self) {
            positions.append(contentsOf: input.map(\.positionAfterSkippingLeadingTrivia))
        } else if let input = parameterClause?.as(ClosureParameterClauseSyntax.self) {
            positions.append(contentsOf: input.parameters.map(\.positionAfterSkippingLeadingTrivia))
        }

        return positions
    }
}
