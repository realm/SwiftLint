import SwiftSyntax

struct SortedEnumCasesRule: ConfigurationProviderRule, SwiftSyntaxRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "sorted_enum_cases",
        name: "Sorted Enum Cases",
        description: "Enum cases should be sorted",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            enum foo {
                case a
                case b
                case c
            }
            """),
            Example("""
            enum foo {
                case a, b, c
            }
            """),
            Example("""
            enum foo {
                case a
                case b, c
            }
            """),
            Example("""
            enum foo {
                case a(foo: Foo)
                case b(String), c
            }
            """),
            Example("""
            @frozen
            enum foo {
                case b
                case a
                case c, f, d
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            enum foo {
                ↓case b
                ↓case a
                case c
            }
            """),
            Example("""
            enum foo {
                case ↓b, ↓a, c
            }
            """),
            Example("""
            enum foo {
                ↓case b, c
                ↓case a
            }
            """),
            Example("""
            enum foo {
                case a
                case b, ↓d, ↓c
            }
            """),
            Example("""
            enum foo {
                case a(foo: Foo)
                case ↓c, ↓b(String)
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension SortedEnumCasesRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            return .allExcept(EnumDeclSyntax.self)
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            guard !node.attributes.contains(attributeNamed: "frozen") else {
                return .skipChildren
            }

            let cases = node.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            let sortedCases = cases
                .sorted(by: { $0.elements.first!.name.text < $1.elements.first!.name.text })

            zip(sortedCases, cases).forEach { sortedCase, currentCase in
                if sortedCase.elements.first?.name.text != currentCase.elements.first?.name.text {
                    violations.append(currentCase.positionAfterSkippingLeadingTrivia)
                }
            }

            return .visitChildren
        }

        override func visitPost(_ node: EnumCaseDeclSyntax) {
            let sortedElements = node.elements.sorted(by: { $0.name.text < $1.name.text })

            zip(sortedElements, node.elements).forEach { sortedElement, currentElement in
                if sortedElement.name.text != currentElement.name.text {
                    violations.append(currentElement.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }
}
