import SwiftSyntax

@SwiftSyntaxRule
struct StaticOverFinalClassRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "static_over_final_class",
        name: "Static Over Final Class",
        description: "Prefer `static` over `final class` for non-overridable declarations",
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

// Stack of flags indicating whether each level in the tree is a final class
private typealias LevelIsFinalClassStack = Stack<Bool>

private extension LevelIsFinalClassStack {
    var lastIsFinalClass: Bool { peek() == true }
}

private extension StaticOverFinalClassRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var levels = LevelIsFinalClassStack()

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            levels.push(node.modifiers.contains(keyword: .final))
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            levels.pop()
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            validateNode(at: node.positionAfterSkippingLeadingTrivia, with: node.modifiers)
            return .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            levels.pop()
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            validateNode(at: node.positionAfterSkippingLeadingTrivia, with: node.modifiers)
            return .visitChildren
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            levels.pop()
        }

        override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
            validateNode(at: node.positionAfterSkippingLeadingTrivia, with: node.modifiers)
            return .visitChildren
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            levels.pop()
        }

        // MARK: -
        private func validateNode(at position: AbsolutePosition, with modifiers: DeclModifierListSyntax) {
            if modifiers.contains(keyword: .final),
               modifiers.contains(keyword: .class) {
                violations.append(position)
            } else if modifiers.contains(keyword: .class),
                      levels.lastIsFinalClass {
                violations.append(position)
            }

            levels.push(false)
        }
    }
}
