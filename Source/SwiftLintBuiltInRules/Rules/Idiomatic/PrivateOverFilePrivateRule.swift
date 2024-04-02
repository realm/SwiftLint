import SwiftSyntax

@SwiftSyntaxRule
struct PrivateOverFilePrivateRule: SwiftSyntaxCorrectableRule {
    var configuration = PrivateOverFilePrivateConfiguration()

    static let description = RuleDescription(
        identifier: "private_over_fileprivate",
        name: "Private over Fileprivate",
        description: "Prefer `private` over `fileprivate` declarations",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("extension String {}"),
            Example("private extension String {}"),
            Example("public \n enum MyEnum {}"),
            Example("open extension \n String {}"),
            Example("internal extension String {}"),
            Example("""
            extension String {
              fileprivate func Something(){}
            }
            """),
            Example("""
            class MyClass {
              fileprivate let myInt = 4
            }
            """),
            Example("""
            actor MyActor {
              fileprivate let myInt = 4
            }
            """),
            Example("""
            class MyClass {
              fileprivate(set) var myInt = 4
            }
            """),
            Example("""
            struct Outter {
              struct Inter {
                fileprivate struct Inner {}
              }
            }
            """)
        ],
        triggeringExamples: [
            Example("↓fileprivate enum MyEnum {}"),
            Example("""
            ↓fileprivate class MyClass {
              fileprivate(set) var myInt = 4
            }
            """),
            Example("""
            ↓fileprivate actor MyActor {
              fileprivate let myInt = 4
            }
            """)
        ],
        corrections: [
            Example("↓fileprivate enum MyEnum {}"):
                Example("private enum MyEnum {}"),
            Example("↓fileprivate enum MyEnum { fileprivate class A {} }"):
                Example("private enum MyEnum { fileprivate class A {} }"),
            Example("↓fileprivate class MyClass { fileprivate(set) var myInt = 4 }"):
                Example("private class MyClass { fileprivate(set) var myInt = 4 }"),
            Example("↓fileprivate actor MyActor { fileprivate(set) var myInt = 4 }"):
                Example("private actor MyActor { fileprivate(set) var myInt = 4 }")
        ]
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
                violations.append(modifier.positionAfterSkippingLeadingTrivia)
                violationCorrections.append(
                    ViolationCorrection(
                        start: modifier.positionAfterSkippingLeadingTrivia,
                        end: modifier.endPositionBeforeTrailingTrivia,
                        replacement: "private"
                    )
                )
            }
        }
    }
}
