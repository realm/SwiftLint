import SwiftSyntax

@SwiftSyntaxRule
struct RedundantSetAccessControlRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_set_access_control",
        name: "Redundant Access Control for Setter",
        description: "Property setter access level shouldn't be explicit if " +
                     "it's the same as the variable access level",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("private(set) public var foo: Int"),
            Example("public let foo: Int"),
            Example("public var foo: Int"),
            Example("var foo: Int"),
            Example("""
            private final class A {
              private(set) var value: Int
            }
            """),
            Example("""
            fileprivate class A {
              public fileprivate(set) var value: Int
            }
            """, excludeFromDocumentation: true),
            Example("""
            extension Color {
                public internal(set) static var someColor = Color.anotherColor
            }
            """),
        ],
        triggeringExamples: [
            Example("↓private(set) private var foo: Int"),
            Example("↓fileprivate(set) fileprivate var foo: Int"),
            Example("↓internal(set) internal var foo: Int"),
            Example("↓public(set) public var foo: Int"),
            Example("""
            open class Foo {
              ↓open(set) open var bar: Int
            }
            """),
            Example("""
            class A {
              ↓internal(set) var value: Int
            }
            """),
            Example("""
            internal class A {
              ↓internal(set) var value: Int
            }
            """),
            Example("""
            fileprivate class A {
              ↓fileprivate(set) var value: Int
            }
            """),
        ]
    )
}

private extension RedundantSetAccessControlRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            [FunctionDeclSyntax.self]
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            let modifiers = node.modifiers
            guard let setAccessor = modifiers.setAccessor else {
                return
            }

            let uniqueModifiers = Set(modifiers.map(\.name.tokenKind))
            if uniqueModifiers.count != modifiers.count {
                violations.append(modifiers.positionAfterSkippingLeadingTrivia)
                return
            }

            if setAccessor.name.tokenKind == .keyword(.fileprivate),
               modifiers.getAccessor == nil,
               let closestDeclModifiers = node.closestDecl()?.modifiers {
                let closestDeclIsFilePrivate = closestDeclModifiers.contains {
                    $0.name.tokenKind == .keyword(.fileprivate)
                }

                if closestDeclIsFilePrivate {
                    violations.append(modifiers.positionAfterSkippingLeadingTrivia)
                    return
                }
            }

            if setAccessor.name.tokenKind == .keyword(.internal),
               modifiers.getAccessor == nil,
               let closesDecl = node.closestDecl(),
               let closestDeclModifiers = closesDecl.modifiers {
                let closestDeclIsInternal = closestDeclModifiers.isEmpty || closestDeclModifiers.contains {
                    $0.name.tokenKind == .keyword(.internal)
                }

                if closestDeclIsInternal {
                    violations.append(modifiers.positionAfterSkippingLeadingTrivia)
                    return
                }
            }
        }
    }
}

private extension SyntaxProtocol {
    func closestDecl() -> DeclSyntax? {
        if let decl = self.parent?.as(DeclSyntax.self) {
            return decl
        }

        return parent?.closestDecl()
    }
}

private extension DeclSyntax {
    var modifiers: DeclModifierListSyntax? {
        self.asProtocol((any WithModifiersSyntax).self)?.modifiers
    }
}

private extension DeclModifierListSyntax {
    var setAccessor: DeclModifierSyntax? {
        first { $0.detail?.detail.tokenKind == .identifier("set") }
    }

    var getAccessor: DeclModifierSyntax? {
        first { $0.detail == nil }
    }
}
