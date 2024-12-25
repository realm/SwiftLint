import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct AnonymousArgumentInMultilineClosureRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

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
            """),
        ],
        triggeringExamples: [
            Example("""
            closure {
                print(↓$0)
            }
            """),
        ]
    )
}

private extension AnonymousArgumentInMultilineClosureRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            let startLocation = locationConverter.location(for: node.leftBrace.positionAfterSkippingLeadingTrivia)
            let endLocation = locationConverter.location(for: node.rightBrace.endPositionBeforeTrailingTrivia)
            return startLocation.line == endLocation.line ? .skipChildren : .visitChildren
        }

        override func visitPost(_ node: DeclReferenceExprSyntax) {
            if case .dollarIdentifier = node.baseName.tokenKind {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
