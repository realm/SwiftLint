import SwiftSyntax

@SwiftSyntaxRule(correctable: true)
struct PrivateOverFilePrivateRule: Rule {
    var configuration = PrivateOverFilePrivateConfiguration()

    static let description = RuleDescription(
        identifier: "private_over_fileprivate",
        name: "Private over Fileprivate",
        description: "Prefer `private` over `fileprivate` declarations",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "extension String {}",
            "private extension String {}",
            "public protocol P {}",
            "open extension \n String {}",
            "internal extension String {}",
            "package typealias P = Int",
            """
            extension String {
              fileprivate func Something(){}
            }
            """,
            """
            class MyClass {
              fileprivate let myInt = 4
            }
            """,
            """
            actor MyActor {
              fileprivate let myInt = 4
            }
            """,
            """
            class MyClass {
              fileprivate(set) var myInt = 4
            }
            """,
            """
            struct Outer {
              struct Inter {
                fileprivate struct Inner {}
              }
            }
            """,
        ]),
        triggeringExamples: #examples([
            "↓fileprivate enum MyEnum {}",
            """
            ↓fileprivate class MyClass {
              fileprivate(set) var myInt = 4
            }
            """,
            """
            ↓fileprivate actor MyActor {
              fileprivate let myInt = 4
            }
            """,
            """
                ↓fileprivate func f() {}
                ↓fileprivate var x = 0
            """,
        ]),
        corrections: #corrections([
            "↓fileprivate enum MyEnum {}":
                "private enum MyEnum {}",
            "↓fileprivate enum MyEnum { fileprivate class A {} }":
                "private enum MyEnum { fileprivate class A {} }",
            "↓fileprivate class MyClass { fileprivate(set) var myInt = 4 }":
                "private class MyClass { fileprivate(set) var myInt = 4 }",
            "↓fileprivate actor MyActor { fileprivate(set) var myInt = 4 }":
                "private actor MyActor { fileprivate(set) var myInt = 4 }",
        ])
    )
}

private extension PrivateOverFilePrivateRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ActorDeclSyntax) {
            visit(withModifier: node)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            visit(withModifier: node)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            visit(withModifier: node)
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if configuration.validateExtensions {
                visit(withModifier: node)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            visit(withModifier: node)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            visit(withModifier: node)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            visit(withModifier: node)
        }

        override func visitPost(_ node: TypeAliasDeclSyntax) {
            visit(withModifier: node)
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            visit(withModifier: node)
        }

        private func visit(withModifier node: some WithModifiersSyntax) {
            if let modifier = node.modifiers.first(where: { $0.name.tokenKind == .keyword(.fileprivate) }) {
                violations.append(
                    at: modifier.positionAfterSkippingLeadingTrivia,
                    correction: .init(
                        start: modifier.positionAfterSkippingLeadingTrivia,
                        end: modifier.endPositionBeforeTrailingTrivia,
                        replacement: "private"
                    )
                )
            }
        }
    }
}
