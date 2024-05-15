import SwiftSyntax

@SwiftSyntaxRule
struct StaticOverFinalClassRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "static_over_final_class",
        name: "Static Over Final Class",
        description: "Prefer `static` over `final class`",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            class C {
                static func f() {}
            }
            """),
            Example("""
            class C {
                static var i: Int { 0 }
            }
            """),
            Example("""
            class C {
                static subscript(_: Int) -> Int { 0 }
            }
            """),
            Example("""
            class C {
                class func f() {}
            }
            """),
            Example("""
            final class C {}
            """),
            Example("""
            final class C {
                class D {
                  class func f() {}
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            class C {
                ↓final class func f() {}
            }
            """),
            Example("""
            class C {
                ↓final class var i: Int { 0 }
            }
            """),
            Example("""
            class C {
                ↓final class subscript(_: Int) -> Int { 0 }
            }
            """),
            Example("""
            final class C {
                ↓class func f() {}
            }
            """),
            Example("""
            class C {
                final class D {
                    ↓class func f() {}
                }
            }
            """)
        ]
    )
}

private extension StaticOverFinalClassRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var classContexts = Stack<Bool>()

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            classContexts.push(node.modifiers.contains(keyword: .final))
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            classContexts.pop()
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            validateNode(at: node.positionAfterSkippingLeadingTrivia, with: node.modifiers)
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            validateNode(at: node.positionAfterSkippingLeadingTrivia, with: node.modifiers)
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            validateNode(at: node.positionAfterSkippingLeadingTrivia, with: node.modifiers)
        }

        // MARK: -
        private func validateNode(at position: AbsolutePosition, with modifiers: DeclModifierListSyntax) {
            if modifiers.contains(keyword: .final),
               modifiers.contains(keyword: .class) {
                violations.append(position)
            } else if modifiers.contains(keyword: .class),
                      classContexts.peek() == true {
                violations.append(position)
            }
        }
    }
}
