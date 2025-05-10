import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct NonOverridableClassDeclarationRule: Rule {
    var configuration = NonOverridableClassDeclarationConfiguration()

    static let description = RuleDescription(
        identifier: "non_overridable_class_declaration",
        name: "Class Declaration in Final Class",
        description: """
            Class methods and properties in final classes should themselves be final, just as if the declarations
            are private. In both cases, they cannot be overridden. Using `final class` or `static` makes this explicit.
            """,
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            final class C {
                final class var b: Bool { true }
                final class func f() {}
            }
            """),
            Example("""
            class C {
                final class var b: Bool { true }
                final class func f() {}
            }
            """),
            Example("""
            class C {
                class var b: Bool { true }
                class func f() {}
            }
            """),
            Example("""
            class C {
                static var b: Bool { true }
                static func f() {}
            }
            """),
            Example("""
            final class C {
                static var b: Bool { true }
                static func f() {}
            }
            """),
            Example("""
            final class C {
                class D {
                    class var b: Bool { true }
                    class func f() {}
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            final class C {
                ↓class var b: Bool { true }
                ↓class func f() {}
            }
            """),
            Example("""
            class C {
                final class D {
                    ↓class var b: Bool { true }
                    ↓class func f() {}
                }
            }
            """),
            Example("""
            class C {
                private ↓class var b: Bool { true }
                private ↓class func f() {}
            }
            """),
        ],
        corrections: [
            Example("""
            final class C {
                class func f() {}
            }
            """): Example("""
                final class C {
                    final class func f() {}
                }
                """),
            Example("""
            final class C {
                class var b: Bool { true }
            }
            """, configuration: ["final_class_modifier": "static"]): Example("""
                final class C {
                    static var b: Bool { true }
                }
                """),
        ]
    )
}

private extension NonOverridableClassDeclarationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var finalClassScope = Stack<Bool>()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            finalClassScope.push(node.modifiers.contains(keyword: .final))
            return .visitChildren
        }

        override func visitPost(_: ClassDeclSyntax) {
            _ = finalClassScope.pop()
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            checkViolations(for: node.modifiers, types: "methods")
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            checkViolations(for: node.modifiers, types: "properties")
        }

        private func checkViolations(for modifiers: DeclModifierListSyntax, types: String) {
            guard !modifiers.contains(keyword: .final),
                  let classKeyword = modifiers.first(where: { $0.name.text == "class" }),
                  case let inFinalClass = finalClassScope.peek() == true,
                  inFinalClass || modifiers.contains(keyword: .private) else {
                return
            }
            violations.append(.init(
                position: classKeyword.positionAfterSkippingLeadingTrivia,
                reason: inFinalClass
                    ? "Class \(types) in final classes should themselves be final"
                    : "Private class methods and properties should be declared final",
                severity: configuration.severity,
                correction: .init(
                    start: classKeyword.positionAfterSkippingLeadingTrivia,
                    end: classKeyword.endPositionBeforeTrailingTrivia,
                    replacement: configuration.finalClassModifier.rawValue
                )
            ))
        }
    }
}
