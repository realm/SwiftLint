import SwiftSyntax

@SwiftSyntaxRule
struct FinalClassRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "final_class",
        name: "Final Class",
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
                class func f() {}
            }
            """),
            Example("""
            final class C {}
            """)
        ],
        triggeringExamples: [
            Example("""
            class C {
                final class func f() {}
            }
            """),
            Example("""
            final class C {
                class func f() {}
            }
            """)
        ]
    )
}

private extension FinalClassRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.modifiers.contains(keyword: .final),
               node.modifiers.contains(keyword: .class) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }

            return .visitChildren
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.modifiers.contains(keyword: .final) {
                node.memberBlock.members
                    .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
                    .filter { $0.modifiers.contains(keyword: .class) }
                    .forEach { violations.append($0.positionAfterSkippingLeadingTrivia) }
            }

            return .visitChildren
        }
    }
}
