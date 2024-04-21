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
            guard node.parentDoesNotContainIgnoredAttributes(for: configuration),
                  let typeAnnotation = node.typeAnnotation,
                  let initializer = node.initializer?.value,
                  typeAnnotation.isRedundant(with: initializer)
            else {
                return
            }
            violations.append(typeAnnotation.positionAfterSkippingLeadingTrivia)
            violationCorrections.append(ViolationCorrection(
                start: typeAnnotation.position,
                end: typeAnnotation.endPositionBeforeTrailingTrivia,
                replacement: ""
            ))
        }

        override func visitPost(_ node: OptionalBindingConditionSyntax) {
            guard let typeAnnotation = node.typeAnnotation,
                  let initializer = node.initializer?.value,
                  typeAnnotation.isRedundant(with: initializer)
            else {
                return
            }
            violations.append(typeAnnotation.positionAfterSkippingLeadingTrivia)
            violationCorrections.append(ViolationCorrection(
                start: typeAnnotation.position,
                end: typeAnnotation.endPositionBeforeTrailingTrivia,
                replacement: ""
            ))
        }
    }
}

private extension TypeAnnotationSyntax {
    func isRedundant(with initializerExpr: ExprSyntax) -> Bool {
        // Extract type and type name from type annotation
        guard let type = type.as(IdentifierTypeSyntax.self) else {
            return false
        }
        let typeName = type.trimmedDescription

        var initializer = initializerExpr
        if let forceUnwrap = initializer.as(ForceUnwrapExprSyntax.self) {
            initializer = forceUnwrap.expression
        }

        // If the initializer is a boolean expression, we consider using the `Bool` type
        // annotation as redundant.
        if initializer.is(BooleanLiteralExprSyntax.self) {
            return typeName == "Bool"
        }

        // If the initializer is a function call (generally a constructor or static builder),
        // check if the base type is the same as the one from the type annotation.
        if let functionCall = initializer.as(FunctionCallExprSyntax.self) {
            if let calledExpression = functionCall.calledExpression.as(DeclReferenceExprSyntax.self) {
                return calledExpression.baseName.text == typeName
            }
            // Parse generic arguments in the intializer if there are any (e.g. var s = Set<Int>(...))
            if let genericSpecialization = functionCall.calledExpression.as(GenericSpecializationExprSyntax.self) {
                // In this case it should be considered redundant if the type name is the same in the type annotation
                // E.g. var s: Set = Set<Int>() should trigger a violation
                return genericSpecialization.expression.trimmedDescription == type.typeName
            }

            // If the function call is a member access expression, check if it is a violation
            return isMemberAccessViolation(node: functionCall.calledExpression, type: type)
        }

        // If the initializer is a member access, check if the base type name is the same as
        // the type annotation
        return isMemberAccessViolation(node: initializer, type: type)
    }

    /// Checks if the given node is a member access (i.e. an enum case or a static property or function)
    /// and if so checks if the base type is the same as the given type name.
    private func isMemberAccessViolation(node: ExprSyntax, type: IdentifierTypeSyntax) -> Bool {
        guard let memberAccess = node.as(MemberAccessExprSyntax.self),
              let base = memberAccess.base
        else {
            // If the type is implicit, `base` will be nil, meaning there is no redundancy.
            return false
        }

        // Parse generic arguments in the intializer if there are any (e.g. var s = Set<Int>(...))
        if let genericSpecialization = base.as(GenericSpecializationExprSyntax.self) {
            // In this case it should be considered redundant if the type name is the same in the type annotation
            // E.g. var s: Set = Set<Int>() should trigger a violation
            return genericSpecialization.expression.trimmedDescription == type.typeName
        }

        // In the case of chained MemberAccessExprSyntax (e.g. let a: A = A.b.c), call this function recursively
        // with the base sequence as root node (in this case A.b).
        if base.is(MemberAccessExprSyntax.self) {
            return isMemberAccessViolation(node: base, type: type)
        }
        // Same for FunctionCallExprSyntax ...
        if let call = base.as(FunctionCallExprSyntax.self) {
            return isMemberAccessViolation(node: call.calledExpression, type: type)
        }
        return base.trimmedDescription == type.trimmedDescription
    }
}

private extension PatternBindingSyntax {
    /// Checks if none of the attributes flagged as ignored in the configuration
    /// are set for this node's parent's parent, if it's a variable declaration
    func parentDoesNotContainIgnoredAttributes(for configuration: RedundantTypeAnnotationConfiguration) -> Bool {
        guard let variableDecl = parent?.parent?.as(VariableDeclSyntax.self) else {
            return true
        }
        return configuration.ignoreAttributes.allSatisfy {
            !variableDecl.attributes.contains(attributeNamed: $0)
        }
    }
}
