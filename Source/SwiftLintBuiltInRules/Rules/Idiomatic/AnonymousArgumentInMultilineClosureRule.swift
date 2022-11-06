import SwiftSyntax

struct AnonymousArgumentInMultilineClosureRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "anonymous_argument_in_multiline_closure",
        name: "Anonymous Argument in Multiline Closure",
        description: "Use named arguments in multiline closures",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("closure { $0 }"),
            Example("closure { print($0) }"),
            Example("""
            closure { arg in
                print(arg)
            }
            """),
            Example("""
            closure { arg in
                nestedClosure { $0 + arg }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            closure {
                print(↓$0)
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(locationConverter: file.locationConverter)
    }
}

private extension AnonymousArgumentInMultilineClosureRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let locationConverter: SourceLocationConverter

        init(locationConverter: SourceLocationConverter) {
            self.locationConverter = locationConverter
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            let startLocation = locationConverter.location(for: node.leftBrace.positionAfterSkippingLeadingTrivia)
            let endLocation = locationConverter.location(for: node.rightBrace.endPositionBeforeTrailingTrivia)

            guard let startLine = startLocation.line, let endLine = endLocation.line, startLine != endLine else {
                return .skipChildren
            }

            return .visitChildren
        }

        override func visitPost(_ node: IdentifierExprSyntax) {
            if case .dollarIdentifier = node.identifier.tokenKind {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
