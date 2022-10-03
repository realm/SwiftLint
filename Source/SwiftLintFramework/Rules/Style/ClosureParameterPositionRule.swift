import SwiftSyntax

public struct ClosureParameterPositionRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_parameter_position",
        name: "Closure Parameter Position",
        description: "Closure parameters should be on the same line as opening brace.",
        kind: .style,
        nonTriggeringExamples: [
            Example("[1, 2].map { $0 + 1 }\n"),
            Example("[1, 2].map({ $0 + 1 })\n"),
            Example("[1, 2].map { number in\n number + 1 \n}\n"),
            Example("[1, 2].map { number -> Int in\n number + 1 \n}\n"),
            Example("[1, 2].map { (number: Int) -> Int in\n number + 1 \n}\n"),
            Example("[1, 2].map { [weak self] number in\n number + 1 \n}\n"),
            Example("[1, 2].something(closure: { number in\n number + 1 \n})\n"),
            Example("let isEmpty = [1, 2].isEmpty()\n"),
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
            """)
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
            """)
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        file.locationConverter.map {
            Visitor(locationConverter: $0)
        }
    }
}

private extension ClosureParameterPositionRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []
        private let locationConverter: SourceLocationConverter

        init(locationConverter: SourceLocationConverter) {
            self.locationConverter = locationConverter
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            guard let signature = node.signature,
                  case let leftBracePosition = node.leftBrace.positionAfterSkippingLeadingTrivia,
                  let startLine = locationConverter.location(for: leftBracePosition).line else {
                return
            }

            let violations = signature.positionsToCheck
                .filter { position in
                    guard let line = locationConverter.location(for: position).line else {
                        return false
                    }

                    return line != startLine
                }

            violationPositions.append(contentsOf: violations)
        }
    }
}

private extension ClosureSignatureSyntax {
    var positionsToCheck: [AbsolutePosition] {
        var positions: [AbsolutePosition] = []
        if let captureItems = capture?.items {
            positions.append(contentsOf: captureItems.map(\.expression.positionAfterSkippingLeadingTrivia))
        }

        if let input = input?.as(ClosureParamListSyntax.self) {
            positions.append(contentsOf: input.map(\.positionAfterSkippingLeadingTrivia))
        } else if let input = input?.as(ParameterClauseSyntax.self) {
            positions.append(contentsOf: input.parameterList.map(\.positionAfterSkippingLeadingTrivia))
        }

        return positions
    }
}
