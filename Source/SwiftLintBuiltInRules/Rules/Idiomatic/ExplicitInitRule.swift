import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct ExplicitInitRule: Rule {
    var configuration = ExplicitInitConfiguration()

    static let description = RuleDescription(
        identifier: "explicit_init",
        name: "Explicit Init",
        description: "Explicitly calling .init() should be avoided",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            import Foundation
            class C: NSObject {
                override init() {
                    super.init()
                }
            }
            """), // super
            Example("""
            struct S {
                let n: Int
            }
            extension S {
                init() {
                    self.init(n: 1)
                }
            }
            """), // self
            Example("""
            [1].flatMap(String.init)
            """), // pass init as closure
            Example("""
            [String.self].map { $0.init(1) }
            """), // initialize from a metatype value
            Example("""
            [String.self].map { type in type.init(1) }
            """), // initialize from a metatype value
            Example("""
            Observable.zip(obs1, obs2, resultSelector: MyType.init).asMaybe()
            """),
            Example("_ = GleanMetrics.Tabs.someType.init()"),
            Example("""
            Observable.zip(
              obs1,
              obs2,
              resultSelector: MyType.init
            ).asMaybe()
            """),
        ],
        triggeringExamples: [
            Example("""
            [1].flatMap{String↓.init($0)}
            """),
            Example("""
            [String.self].map { Type in Type↓.init(1) }
            """),  // Starting with capital letter assumes a type
            Example("""
            func foo() -> [String] {
                return [1].flatMap { String↓.init($0) }
            }
            """),
            Example("_ = GleanMetrics.Tabs.GroupedTabExtra↓.init()"),
            Example("_ = Set<KsApi.Category>↓.init()"),
            Example("""
            Observable.zip(
              obs1,
              obs2,
              resultSelector: { MyType↓.init($0, $1) }
            ).asMaybe()
            """),
            Example("""
            let int = In🤓t↓
            .init(1.0)
            """, excludeFromDocumentation: true),
            Example("""
            let int = Int↓


            .init(1.0)
            """, excludeFromDocumentation: true),
            Example("""
            let int = Int↓


                  .init(1.0)
            """, excludeFromDocumentation: true),
        ],
        corrections: [
            Example("""
            [1].flatMap{String↓.init($0)}
            """):
                Example("""
                [1].flatMap{String($0)}
                """),
            Example("""
            func foo() -> [String] {
                return [1].flatMap { String↓.init($0) }
            }
            """):
                Example("""
                func foo() -> [String] {
                    return [1].flatMap { String($0) }
                }
                """),
            Example("""
            class C {
            #if true
                func f() {
                    [1].flatMap{String↓.init($0)}
                }
            #endif
            }
            """):
                Example("""
                class C {
                #if true
                    func f() {
                        [1].flatMap{String($0)}
                    }
                #endif
                }
                """),
            Example("""
            let int = Int↓
            .init(1.0)
            """):
                Example("""
                let int = Int(1.0)
                """),
            Example("""
            let int = Int↓


            .init(1.0)
            """):
                Example("""
                let int = Int(1.0)
                """),
            Example("""
            let int = Int↓


                  .init(1.0)
            """):
                Example("""
                let int = Int(1.0)
                """),
            Example("""
            let int = Int↓


                  .init(1.0)



            """):
                Example("""
                let int = Int(1.0)



                """),
            Example("""
            f { e in
                // comment
                A↓.init(e: e)
            }
            """):
                Example("""
                f { e in
                    // comment
                    A(e: e)
                }
                """),
            Example("_ = GleanMetrics.Tabs.GroupedTabExtra↓.init()"):
                Example("_ = GleanMetrics.Tabs.GroupedTabExtra()"),
            Example("_ = Set<KsApi.Category>↓.init()"):
                Example("_ = Set<KsApi.Category>()"),
        ]
    )
}

private extension ExplicitInitRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self) else {
                return
            }

            if let violationPosition = calledExpression.explicitInitPosition {
                violations.append(violationPosition)
            }

            if configuration.includeBareInit, let violationPosition = calledExpression.bareInitPosition {
                let reason = "Prefer named constructors over .init and type inference"
                violations.append(ReasonedRuleViolation(position: violationPosition, reason: reason))
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                  let violationPosition = calledExpression.explicitInitPosition,
                  let calledBase = calledExpression.base else {
                return super.visit(node)
            }
            correctionPositions.append(violationPosition)
            let newNode = node.with(\.calledExpression, calledBase)
            return super.visit(newNode)
        }
    }
}

private extension MemberAccessExprSyntax {
    var explicitInitPosition: AbsolutePosition? {
        if let base, base.isTypeReferenceLike, declName.baseName.text == "init" {
            return base.endPositionBeforeTrailingTrivia
        }
        return nil
    }

    var bareInitPosition: AbsolutePosition? {
        if base == nil, declName.baseName.text == "init" {
            return period.positionAfterSkippingLeadingTrivia
        }
        return nil
    }
}

private extension ExprSyntax {
    /// `String` or `Nested.Type`.
    var isTypeReferenceLike: Bool {
        if let expr = self.as(DeclReferenceExprSyntax.self), expr.baseName.text.startsWithUppercase {
            return true
        }
        if let expr = self.as(MemberAccessExprSyntax.self),
                  expr.description.split(separator: ".").allSatisfy(\.startsWithUppercase) {
            return true
        }
        if let expr = self.as(GenericSpecializationExprSyntax.self)?.expression.as(DeclReferenceExprSyntax.self),
                  expr.baseName.text.startsWithUppercase {
            return true
        }
        return false
    }
}

private extension StringProtocol {
    var startsWithUppercase: Bool { first?.isUppercase == true }
}
