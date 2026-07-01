import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct RedundantTypeAnnotationRule: Rule {
    var configuration = RedundantTypeAnnotationConfiguration()

    static let description = RuleDescription(
        identifier: "redundant_type_annotation",
        name: "Redundant Type Annotation",
        description: "Variables should not have redundant type annotation",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "var url = URL()",
            "var url: CustomStringConvertible = URL()",
            "var one: Int = 1, two: Int = 2, three: Int",
            "guard let url = URL() else { return }",
            "if let url = URL() { return }",
            "let alphanumerics = CharacterSet.alphanumerics",
            "var set: Set<Int> = Set([])",
            "var set: Set<Int> = Set.init([])",
            "var set = Set<Int>([])",
            "var set = Set<Int>.init([])",
            "guard var set: Set<Int> = Set([]) else { return }",
            "if var set: Set<Int> = Set.init([]) { return }",
            "guard var set = Set<Int>([]) else { return }",
            "if var set = Set<Int>.init([]) { return }",
            "var one: A<T> = B()",
            "var one: A = B<T>()",
            "var one: A<T> = B<T>()",
            "let a = A.b.c.d",
            "let a: B = A.b.c.d",
            """
            enum Direction {
                case up
                case down
            }

            var direction: Direction = .up
            """,
            """
            enum Direction {
                case up
                case down
            }

            var direction = Direction.up
            """,
            "@IgnoreMe var a: Int = Int(5)".configuration(["ignore_attributes": ["IgnoreMe"]]),
            """
            var a: Int {
                @IgnoreMe let i: Int = Int(1)
                return i
            }
            """.configuration(["ignore_attributes": ["IgnoreMe"]]),
            "var bol: Bool = true",
            "var dbl: Double = 0.0",
            "var int: Int = 0",
            "var str: String = \"str\"",
            """
            struct Foo {
                var url: URL = URL()
                let myVar: Int? = 0, s: String = ""
            }
            """.configuration(["ignore_properties": true]),
        ]),
        triggeringExamples: #examples([
            "var url↓:URL=URL()",
            "var url↓:URL = URL(string: \"\")",
            "var url↓: URL = URL()",
            "let url↓: URL = URL()",
            "lazy var url↓: URL = URL()",
            "let url↓: URL = URL()!",
            "var one: Int = 1, two↓: Int = Int(5), three: Int",
            "guard let url↓: URL = URL() else { return }",
            "if let url↓: URL = URL() { return }",
            "let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics",
            "var set↓: Set<Int> = Set<Int>([])",
            "var set↓: Set<Int> = Set<Int>.init([])",
            "var set↓: Set = Set<Int>([])",
            "var set↓: Set = Set<Int>.init([])",
            "guard var set↓: Set = Set<Int>([]) else { return }",
            "if var set↓: Set = Set<Int>.init([]) { return }",
            "guard var set↓: Set<Int> = Set<Int>([]) else { return }",
            "if var set↓: Set<Int> = Set<Int>.init([]) { return }",
            "var set↓: Set = Set<Int>([]), otherSet: Set<Int>",
            "var num↓: Int = Int.random(0..<10)",
            "let a↓: A = A.b.c.d",
            "let a↓: A = A.f().b",
            """
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """,
            """
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """.configuration(["ignore_properties": true]),
            "let a↓: [Int] = [Int]()",
            "let a↓: A.B = A.B()",
            """
            enum Direction {
                case up
                case down
            }

            var direction↓: Direction = Direction.up
            """,
            "@DontIgnoreMe var a↓: Int = Int(5)".configuration(["ignore_attributes": ["IgnoreMe"]]),
            """
            @IgnoreMe
            var a: Int {
                let i↓: Int = Int(1)
                return i
            }
            """.configuration(["ignore_attributes": ["IgnoreMe"]]),
            "var bol↓: Bool = true".configuration(["consider_default_literal_types_redundant": true]),
            "var dbl↓: Double = 0.0".configuration(["consider_default_literal_types_redundant": true]),
            "var int↓: Int = 0".configuration(["consider_default_literal_types_redundant": true]),
            "var str↓: String = \"str\"".configuration(["consider_default_literal_types_redundant": true]),
        ]),
        corrections: #examplesDictionary([
            "var url↓: URL = URL()": "var url = URL()",
            "let url↓: URL = URL()": "let url = URL()",
            "var one: Int = 1, two↓: Int = Int(5), three: Int":
                "var one: Int = 1, two = Int(5), three: Int",
            "guard let url↓: URL = URL() else { return }":
                "guard let url = URL() else { return }",
            "if let url↓: URL = URL() { return }":
                "if let url = URL() { return }",
            "let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics":
                "let alphanumerics = CharacterSet.alphanumerics",
            "var set↓: Set<Int> = Set<Int>([])":
                "var set = Set<Int>([])",
            "var set↓: Set<Int> = Set<Int>.init([])":
                "var set = Set<Int>.init([])",
            "var set↓: Set = Set<Int>([])":
                "var set = Set<Int>([])",
            "var set↓: Set = Set<Int>.init([])":
                "var set = Set<Int>.init([])",
            "guard var set↓: Set<Int> = Set<Int>([]) else { return }":
                "guard var set = Set<Int>([]) else { return }",
            "if var set↓: Set<Int> = Set<Int>.init([]) { return }":
                "if var set = Set<Int>.init([]) { return }",
            "var set↓: Set = Set<Int>([]), otherSet: Set<Int>":
                "var set = Set<Int>([]), otherSet: Set<Int>",
            "let a↓: A = A.b.c.d":
                "let a = A.b.c.d",
            """
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """:
            """
            class ViewController: UIViewController {
              func someMethod() {
                let myVar = Int(5)
              }
            }
            """,
            "var num: Int = Int.random(0..<10)": "var num = Int.random(0..<10)",
            """
            @IgnoreMe
            var a: Int {
                let i↓: Int = Int(1)
                return i
            }
            """.configuration(["ignore_attributes": ["IgnoreMe"]]):
            """
            @IgnoreMe
            var a: Int {
                let i = Int(1)
                return i
            }
            """,
            "var bol: Bool = true".configuration(["consider_default_literal_types_redundant": true]):
                "var bol = true",
            "var dbl: Double = 0.0".configuration(["consider_default_literal_types_redundant": true]):
                "var dbl = 0.0",
            "var int: Int = 0".configuration(["consider_default_literal_types_redundant": true]):
                "var int = 0",
            "var str: String = \"str\"".configuration(["consider_default_literal_types_redundant": true]):
                "var str = \"str\"",
        ])
    )
}

private extension RedundantTypeAnnotationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: PatternBindingSyntax) {
            if let varDecl = node.parent?.parent?.as(VariableDeclSyntax.self),
               !configuration.shouldSkipRuleCheck(for: varDecl),
               let typeAnnotation = node.typeAnnotation,
               let initializer = node.initializer?.value {
                collectViolation(forType: typeAnnotation, withInitializer: initializer)
            }
        }

        override func visitPost(_ node: OptionalBindingConditionSyntax) {
            if let typeAnnotation = node.typeAnnotation,
               let initializer = node.initializer?.value {
                collectViolation(forType: typeAnnotation, withInitializer: initializer)
            }
        }

        private func collectViolation(forType type: TypeAnnotationSyntax, withInitializer initializer: ExprSyntax) {
            let validateLiterals = configuration.considerDefaultLiteralTypesRedundant
            let isLiteralRedundant = validateLiterals && initializer.hasRedundant(literalType: type.type)
            guard isLiteralRedundant || initializer.hasRedundant(type: type.type) else {
                return
            }
            violations.append(
                at: type.positionAfterSkippingLeadingTrivia,
                correction: .init(
                    start: type.position,
                    end: type.endPositionBeforeTrailingTrivia,
                    replacement: ""
                )
            )
        }
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

    func hasRedundant(literalType type: TypeSyntax) -> Bool {
        type.trimmedDescription == kind.compilerInferredLiteralType
    }

    func hasRedundant(type: TypeSyntax) -> Bool {
        `as`(ForceUnwrapExprSyntax.self)?.expression.hasRedundant(type: type)
            ?? accessedNames.contains(type.trimmedDescription)
    }
}

private extension SyntaxKind {
    var compilerInferredLiteralType: String? {
        switch self {
        case .booleanLiteralExpr:
            "Bool"
        case .floatLiteralExpr:
            "Double"
        case .integerLiteralExpr:
            "Int"
        case .stringLiteralExpr:
            "String"
        default:
            nil
        }
    }
}

extension RedundantTypeAnnotationConfiguration {
    func shouldSkipRuleCheck(for varDecl: VariableDeclSyntax) -> Bool {
        if ignoreAttributes.contains(where: { varDecl.attributes.contains(attributeNamed: $0) }) {
            return true
        }

        return ignoreProperties && varDecl.parent?.is(MemberBlockItemSyntax.self) == true
    }
}
