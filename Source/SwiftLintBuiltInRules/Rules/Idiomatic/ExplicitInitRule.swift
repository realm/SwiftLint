import SwiftSyntax
import SwiftSyntaxBuilder

struct ExplicitInitRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

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
            """)
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
            """, excludeFromDocumentation: true)
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
            Example("_ = GleanMetrics.Tabs.GroupedTabExtra↓.init()"):
                Example("_ = GleanMetrics.Tabs.GroupedTabExtra()"),
            Example("_ = Set<KsApi.Category>↓.init()"):
                Example("_ = Set<KsApi.Category>()")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension ExplicitInitRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                let violationPosition = calledExpression.explicitInitPosition
            else {
                return
            }

            violations.append(violationPosition)
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                let violationPosition = calledExpression.explicitInitPosition,
                let calledBase = calledExpression.base,
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(violationPosition)
            return super.visit(node.withCalledExpression("\(calledBase.withoutTrivia())"))
        }
    }
}

private extension MemberAccessExprSyntax {
    var explicitInitPosition: AbsolutePosition? {
        if let base = base, base.isTypeReferenceLike, name.text == "init" {
            return base.endPositionBeforeTrailingTrivia
        } else {
            return nil
        }
    }
}

private extension ExprSyntax {
    /// `String` or `Nested.Type`.
    var isTypeReferenceLike: Bool {
        if let expr = self.as(IdentifierExprSyntax.self), expr.identifier.text.startsWithUppercase {
            return true
        } else if let expr = self.as(MemberAccessExprSyntax.self),
                  expr.description.split(separator: ".").allSatisfy(\.startsWithUppercase) {
            return true
        } else if let expr = self.as(SpecializeExprSyntax.self)?.expression.as(IdentifierExprSyntax.self),
                  expr.identifier.text.startsWithUppercase {
            return true
        } else {
            return false
        }
    }
}

private extension StringProtocol {
    var startsWithUppercase: Bool { first?.isUppercase == true }
}
