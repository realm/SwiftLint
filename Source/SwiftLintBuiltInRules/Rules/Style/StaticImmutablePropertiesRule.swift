import SwiftSyntax

struct StaticImmutablePropertiesRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "static_immutable_properties",
        name: "Static immutable properies",
        description: "Prefer making initialized immutable properties static",
        kind: .style,
        nonTriggeringExamples: nonTriggeringExamples,
        triggeringExamples: triggeringExamples
    )

    init() {}

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension StaticImmutablePropertiesRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberDeclListSyntax) {
            let nonStaticProperties: [VariableDeclSyntax] = node.compactMap({ item in
                guard item.decl.kind == .variableDecl else {
                    // need variable decls
                    return nil
                }
                guard let variableSyntax = item.decl.as(VariableDeclSyntax.self) else {
                    return nil
                }
                let modifiers = variableSyntax.modifiers ?? []
                guard modifiers.allSatisfy({ modifier in
                    return modifier.name.tokenKind != .keyword(.static)
                }) else {
                    // no static modifier
                    return nil
                }
                guard variableSyntax.as(TokenSyntax.self)?.tokenKind == .keyword(.let) else {
                    // should be an immutable property
                    return nil
                }
                guard variableSyntax.bindings.contains(where: { syntax in
                    return syntax.initializer?.kind == .initializerClause
                }) else {
                    // should be an initialisation clause
                    return nil
                }
                return variableSyntax
            })
            // and report positions of the lets
            let allPositions = nonStaticProperties.map { syntax in
                return syntax.positionAfterSkippingLeadingTrivia
            }
            self.violations.append(contentsOf: allPositions)
        }
    }
}

private extension StaticImmutablePropertiesRule {
    static let nonTriggeringExamples: [Example] = [
        Example("""
        class Foo {
            static let constant: Int = 1
            var variable: Int = 2
        }
        """),
        Example("""
        struct Foo {
            static let constant: Int = 1
        }
        """),
        Example("""
        enum InstFooance {
            static let constant = 1
        }
        """),
        Example("""
        struct Foo {
            let property1
            let property2
            init(property1: Int, property2: String) {
                self.property1 = property1
                self.property2 = property2
            }
        }
        """)
    ]

    static let triggeringExamples: [Example] = [
        Example("""
        class Foo {
            static let one = 32
            ↓let constant: Int = 1
        }
        """),
        Example("""
        struct Foo {
            ↓let constant: Int = 1
        }
        """),
        Example("""
        enum Foo {
            ↓let constant: Int = 1
        }
        """),
        Example("""
        enum Foo {
            ↓let constant = "Xddd"
        }
        """)
    ]
}
