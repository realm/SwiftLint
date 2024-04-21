import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct RedundantTypeAnnotationRule: OptInRule, SwiftSyntaxCorrectableRule {
    var configuration = RedundantTypeAnnotationConfiguration()

    static let description = RuleDescription(
        identifier: "redundant_type_annotation",
        name: "Redundant Type Annotation",
        description: "Variables should not have redundant type annotation",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var url = URL()"),
            Example("var url: CustomStringConvertible = URL()"),
            Example("var one: Int = 1, two: Int = 2, three: Int"),
            Example("guard let url = URL() else { return }"),
            Example("if let url = URL() { return }"),
            Example("let alphanumerics = CharacterSet.alphanumerics"),
            Example("var set: Set<Int> = Set([])"),
            Example("var set: Set<Int> = Set.init([])"),
            Example("var set = Set<Int>([])"),
            Example("var set = Set<Int>.init([])"),
            Example("guard var set: Set<Int> = Set([]) else { return }"),
            Example("if var set: Set<Int> = Set.init([]) { return }"),
            Example("guard var set = Set<Int>([]) else { return }"),
            Example("if var set = Set<Int>.init([]) { return }"),
            Example("var one: A<T> = B()"),
            Example("var one: A = B<T>()"),
            Example("var one: A<T> = B<T>()"),
            Example("let a = A.b.c.d"),
            Example("let a: B = A.b.c.d"),
            Example("""
            enum Direction {
                case up
                case down
            }

            var direction: Direction = .up
            """),
            Example("""
            enum Direction {
                case up
                case down
            }

            var direction = Direction.up
            """),
            Example("@IgnoreMe var a: Int = Int(5)", configuration: ["ignore_attributes": ["IgnoreMe"]]),
            Example("""
            var a: Int {
                @IgnoreMe let i: Int = Int(1)
                return i
            }
            """, configuration: ["ignore_attributes": ["IgnoreMe"]])
        ],
        triggeringExamples: [
            Example("var url↓:URL=URL()"),
            Example("var url↓:URL = URL(string: \"\")"),
            Example("var url↓: URL = URL()"),
            Example("let url↓: URL = URL()"),
            Example("lazy var url↓: URL = URL()"),
            Example("let url↓: URL = URL()!"),
            Example("var one: Int = 1, two↓: Int = Int(5), three: Int"),
            Example("guard let url↓: URL = URL() else { return }"),
            Example("if let url↓: URL = URL() { return }"),
            Example("let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics"),
            Example("var set↓: Set<Int> = Set<Int>([])"),
            Example("var set↓: Set<Int> = Set<Int>.init([])"),
            Example("var set↓: Set = Set<Int>([])"),
            Example("var set↓: Set = Set<Int>.init([])"),
            Example("guard var set↓: Set = Set<Int>([]) else { return }"),
            Example("if var set↓: Set = Set<Int>.init([]) { return }"),
            Example("guard var set↓: Set<Int> = Set<Int>([]) else { return }"),
            Example("if var set↓: Set<Int> = Set<Int>.init([]) { return }"),
            Example("var set↓: Set = Set<Int>([]), otherSet: Set<Int>"),
            Example("var num↓: Int = Int.random(0..<10)"),
            Example("let a↓: A = A.b.c.d"),
            Example("let a↓: A = A.f().b"),
            Example("""
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """),
            Example("var isEnabled↓: Bool = true"),
            Example("let a↓: [Int] = [Int]()"),
            Example("let a↓: A.B = A.B()"),
            Example("""
            enum Direction {
                case up
                case down
            }

            var direction↓: Direction = Direction.up
            """),
            Example("@DontIgnoreMe var a↓: Int = Int(5)", configuration: ["ignore_attributes": ["IgnoreMe"]]),
            Example("""
            @IgnoreMe
            var a: Int {
                let i↓: Int = Int(1)
                return i
            }
            """, configuration: ["ignore_attributes": ["IgnoreMe"]])
        ],
        corrections: [
            Example("var url↓: URL = URL()"): Example("var url = URL()"),
            Example("let url↓: URL = URL()"): Example("let url = URL()"),
            Example("var one: Int = 1, two↓: Int = Int(5), three: Int"):
                Example("var one: Int = 1, two = Int(5), three: Int"),
            Example("guard let url↓: URL = URL() else { return }"):
                Example("guard let url = URL() else { return }"),
            Example("if let url↓: URL = URL() { return }"):
                Example("if let url = URL() { return }"),
            Example("let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics"):
                Example("let alphanumerics = CharacterSet.alphanumerics"),
            Example("var set↓: Set<Int> = Set<Int>([])"):
                Example("var set = Set<Int>([])"),
            Example("var set↓: Set<Int> = Set<Int>.init([])"):
                Example("var set = Set<Int>.init([])"),
            Example("var set↓: Set = Set<Int>([])"):
                Example("var set = Set<Int>([])"),
            Example("var set↓: Set = Set<Int>.init([])"):
                Example("var set = Set<Int>.init([])"),
            Example("guard var set↓: Set<Int> = Set<Int>([]) else { return }"):
                Example("guard var set = Set<Int>([]) else { return }"),
            Example("if var set↓: Set<Int> = Set<Int>.init([]) { return }"):
                Example("if var set = Set<Int>.init([]) { return }"),
            Example("var set↓: Set = Set<Int>([]), otherSet: Set<Int>"):
                Example("var set = Set<Int>([]), otherSet: Set<Int>"),
            Example("let a↓: A = A.b.c.d"):
                Example("let a = A.b.c.d"),
            Example("""
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """):
            Example("""
            class ViewController: UIViewController {
              func someMethod() {
                let myVar = Int(5)
              }
            }
            """),
            Example("var num: Int = Int.random(0..<10)"): Example("var num = Int.random(0..<10)"),
            Example("""
            @IgnoreMe
            var a: Int {
                let i↓: Int = Int(1)
                return i
            }
            """, configuration: ["ignore_attributes": ["IgnoreMe"]]):
            Example("""
            @IgnoreMe
            var a: Int {
                let i = Int(1)
                return i
            }
            """)
        ]
    )
}

private extension RedundantTypeAnnotationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: PatternBindingSyntax) {
            guard let varDecl = node.parent?.parent?.as(VariableDeclSyntax.self),
                  configuration.ignoreAttributes.allSatisfy({ !varDecl.attributes.contains(attributeNamed: $0) }) else {
                return
            }
            if let typeAnnotation = node.typeAnnotation,
               let initializer = node.initializer?.value,
               typeAnnotation.isRedundant(with: initializer) {
                violations.append(typeAnnotation.positionAfterSkippingLeadingTrivia)
                violationCorrections.append(ViolationCorrection(
                    start: typeAnnotation.position,
                    end: typeAnnotation.endPositionBeforeTrailingTrivia,
                    replacement: ""
                ))
            }
        }

        override func visitPost(_ node: OptionalBindingConditionSyntax) {
            if let typeAnnotation = node.typeAnnotation,
               let initializer = node.initializer?.value,
               typeAnnotation.isRedundant(with: initializer) {
                violations.append(typeAnnotation.positionAfterSkippingLeadingTrivia)
                violationCorrections.append(ViolationCorrection(
                    start: typeAnnotation.position,
                    end: typeAnnotation.endPositionBeforeTrailingTrivia,
                    replacement: ""
                ))
            }
        }
    }
}

private extension TypeAnnotationSyntax {
    func isRedundant(with initializerExpr: ExprSyntax) -> Bool {
        var initializer = initializerExpr
        if let forceUnwrap = initializer.as(ForceUnwrapExprSyntax.self) {
            initializer = forceUnwrap.expression
        }

        // If the initializer is a boolean expression, we consider using the `Bool` type
        // annotation as redundant.
        if initializer.is(BooleanLiteralExprSyntax.self) {
            return type.trimmedDescription == "Bool"
        }
        return initializer.accessedNames.contains(type.trimmedDescription)
    }
}

private extension ExprSyntax {
    /// An expression can represent an access to an identifier in one or another way depending on the exact underlying
    /// expression type. E.g. the expression `A` accesses `A` while `f()` accesses `f` and `a.b.c` accesses `a` in the
    /// sense of this property. In the context of this rule, `Set<Int>()` accesses `Set` as well as `Set<Int>`.
    var accessedNames: [String] {
        if let declRef = `as`(DeclReferenceExprSyntax.self) {
            [declRef.trimmedDescription]
        } else if let memberAccess = `as`(MemberAccessExprSyntax.self) {
            (memberAccess.base?.accessedNames ?? []) + [memberAccess.trimmedDescription]
        } else if let genericSpecialization = `as`(GenericSpecializationExprSyntax.self) {
            [genericSpecialization.trimmedDescription] + genericSpecialization.expression.accessedNames
        } else if let call = `as`(FunctionCallExprSyntax.self) {
            call.calledExpression.accessedNames
        } else if let arrayExpr = `as`(ArrayExprSyntax.self) {
            [arrayExpr.trimmedDescription]
        } else {
            []
        }
    }
}
