import SwiftSyntax
import SwiftSyntaxBuilder

struct BareInitRule: ConfigurationProviderRule, SwiftSyntaxRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "bare_init",
        name: "Bare Init",
        description: "Prefer named constructors over .init and type inference",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let foo = Foo()"),
            Example("let foo = init()"),
            Example("let foo = Foo.init()")
        ],
        triggeringExamples: [
            Example("let foo: Foo = ↓.init()"),
            Example("let foo: [Foo] = [↓.init(), ↓.init()]"),
            Example("foo(↓.init())")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension BareInitRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                let violationPosition = calledExpression.bareInitPosition
            else {
                return
            }

            violations.append(violationPosition)
        }
    }
}

private extension MemberAccessExprSyntax {
    var bareInitPosition: AbsolutePosition? {
        if base == nil, name.text == "init" {
            return dot.positionAfterSkippingLeadingTrivia
        } else {
            return nil
        }
    }
}
