import SwiftSyntax

struct RedundantSetAccessControlRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "redundant_set_access_control",
        name: "Redundant Access Control for Setter",
        description: "Property setter access level shouldn't be explicit if " +
                     "it's the same as the variable access level.",
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
            """)
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
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension RedundantSetAccessControlRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            [FunctionDeclSyntax.self]
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            guard let modifiers = node.modifiers, let setAccessor = modifiers.setAccessor else {
                return
            }

            let uniqueModifiers = Set(modifiers.map(\.name.tokenKind))
            if uniqueModifiers.count != modifiers.count {
                violations.append(modifiers.positionAfterSkippingLeadingTrivia)
                return
            }

            if setAccessor.name.tokenKind == .fileprivateKeyword,
               modifiers.getAccessor == nil,
               let closestDeclModifiers = node.closestDecl()?.modifiers {
                let closestDeclIsFilePrivate = closestDeclModifiers.contains {
                    $0.name.tokenKind == .fileprivateKeyword
                }

                if closestDeclIsFilePrivate {
                    violations.append(modifiers.positionAfterSkippingLeadingTrivia)
                    return
                }
            }

            if setAccessor.name.tokenKind == .internalKeyword,
               modifiers.getAccessor == nil,
               let closesDecl = node.closestDecl(),
               let closestDeclModifiers = closesDecl.modifiers {
                let closestDeclIsInternal = closestDeclModifiers.isEmpty || closestDeclModifiers.contains {
                    $0.name.tokenKind == .internalKeyword
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
    var modifiers: ModifierListSyntax? {
        if let decl = self.as(ClassDeclSyntax.self) {
            return decl.modifiers ?? ModifierListSyntax([])
        } else if let decl = self.as(ActorDeclSyntax.self) {
            return decl.modifiers ?? ModifierListSyntax([])
        } else if let decl = self.as(StructDeclSyntax.self) {
            return decl.modifiers ?? ModifierListSyntax([])
        } else if let decl = self.as(ProtocolDeclSyntax.self) {
            return decl.modifiers ?? ModifierListSyntax([])
        } else if let decl = self.as(ExtensionDeclSyntax.self) {
            return decl.modifiers ?? ModifierListSyntax([])
        } else if let decl = self.as(EnumDeclSyntax.self) {
            return decl.modifiers ?? ModifierListSyntax([])
        }

        return nil
    }
}

private extension ModifierListSyntax {
    var setAccessor: DeclModifierSyntax? {
        first { $0.detail?.detail.tokenKind == .contextualKeyword("set") }
    }

    var getAccessor: DeclModifierSyntax? {
        first { $0.detail == nil }
    }
}
